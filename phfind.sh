show_help() {
    echo "Uso: $0 [diretório(s)] [opções]"
    echo "Opções:"
    echo "  -name [padrão]        Nome do arquivo ou parte do nome (com suporte a curingas)"
    echo "  -type [d|f]           Tipo de arquivo (d para diretório, f para arquivo)"
    echo "  -size [+-][N][c|k|M]  Tamanho do arquivo (+ maior que, - menor que, N exato)"
    echo "  -mtime [+-]N          Arquivos modificados há N dias (+ mais antigo, - mais recente)"
    echo "  -cnewer [arquivo]     Arquivos mais recentes que o arquivo de referência"
    echo "  -regex [padrão]       Expressão regular para correspondência de caminho completo"
    echo "  -help                 Exibe esta mensagem de ajuda"
}

if [[ "$1" == "-help" ]]; then
    show_help
    exit 0
fi

directories=()
name=""
type=""
size=""
mtime=""
cnewer=""
regex=""

# Processa os parâmetros
while [[ $# -gt 0 ]]; do
    case "$1" in
        -name)
            if [[ -z "$2" ]]; then
                echo "phfind: missing argument for -name"
                exit 1
            fi
            name="$2"
            shift 2
            ;;
        -type)
            if [[ -z "$2" || ! "$2" =~ ^[df]$ ]]; then
                echo "phfind: invalid argument '$2' to '-type'"
                exit 1
            fi
            type="$2"
            shift 2
            ;;
        -size)
            if [[ -z "$2" || ! "$2" =~ ^[+-]?[0-9]+[c|k|M]?$ ]]; then
                echo "phfind: invalid argument '$2' to '-size'"
                exit 1
            fi
            size="$2"
            shift 2
            ;;
        -mtime)
            if [[ -z "$2" || ! "$2" =~ ^[+-]?[0-9]+$ ]]; then
                echo "phfind: invalid argument '$2' to '-mtime'"
                exit 1
            fi
            mtime="$2"
            shift 2
            ;;
        -cnewer)
            if [[ -z "$2" || ! -e "$2" ]]; then
                echo "phfind: invalid argument '$2' to '-cnewer'"
                exit 1
            fi
            cnewer="$2"
            shift 2
            ;;
        -regex)
            if [[ -z "$2" ]]; then
                echo "phfind: missing argument for -regex"
                exit 1
            fi
            regex="$2"
            shift 2
            ;;
        -*)
            echo "phfind: unknown predicate $1"
            exit 1
            ;;
        *)
            directories+=("$1")
            shift
            ;;
    esac
done

# Verifica se pelo menos um diretório foi fornecido
if [[ ${#directories[@]} -eq 0 ]]; then
    directories+=(".")
fi

convert_to_bytes() {
    local size_str=$1
    local unit=${size_str: -1}
    local value=${size_str%?}

    case $unit in
        c) echo $value ;;
        k) echo $((value * 1024)) ;;
        M) echo $((value * 1024 * 1024)) ;;
        *) echo $size_str ;;
    esac
}

test_size() {
    local filesize=$1
    local size=$2

    local sign=${size:0:1}
    local size_value
    local size_in_bytes

    if [[ "$sign" =~ [+-] ]]; then
        size_value=${size:1}
    else
        sign=""
        size_value=$size
    fi

    size_in_bytes=$(convert_to_bytes "$size_value")

    case "$sign" in
        +) [[ "$filesize" -le "$size_in_bytes" ]] && return 1 ;;
        -) [[ "$filesize" -ge "$size_in_bytes" ]] && return 1 ;;
        *) [[ "$filesize" -ne "$size_in_bytes" ]] && return 1 ;;
    esac

    return 0
}

test_mtime() {
    local fileage=$1
    local mtime=$2

    local sign=${mtime:0:1}
    local mtime_value

    if [[ "$sign" =~ [+-] ]]; then
        mtime_value=${mtime:1}
    else
        sign=""
        mtime_value=$mtime
    fi

    local mtime_in_seconds=$((mtime_value * 86400))

    case "$sign" in
        +) [[ "$fileage" -le "$mtime_in_seconds" ]] && return 1 ;;
        -) [[ "$fileage" -ge "$mtime_in_seconds" ]] && return 1 ;;
        *) [[ "$fileage" -ne "$mtime_in_seconds" ]] && return 1 ;;
    esac

    return 0
}

test_type() {
    local entry=$1
    local type=$2

    if ([[ "$type" == "d" && ! -d "$entry" ]] || [[ "$type" == "f" && ! -f "$entry" ]]); then
        return 1
    fi

    return 0
}

test_cnewer() {
    local entry=$1
    local reference_file=$2

    local entry_ctime=$(stat -c%Z "$entry")
    local reference_mtime=$(stat -c%Y "$reference_file")

    [[ "$entry_ctime" -gt "$reference_mtime" ]]
}

check_and_print_entry() {
    local entry=$1
    local now=$(date +%s)
    
    local filename=$(basename "$entry")
    local filesize=$(stat -c%s "$entry")
    local filemod=$(stat -c%Y "$entry")
    local fileage=$((now - filemod))
    local filepath=$(realpath "$entry")

    if [[ -n "$name" && ! "$filename" == $name ]]; then
        return
    fi

    if [[ -n "$type" ]]; then
        if ! test_type "$entry" "$type"; then
            return
        fi
    fi

    if [[ -n "$size" ]]; then
        if ! test_size "$filesize" "$size"; then
            return
        fi
    fi

    if [[ -n "$mtime" ]]; then
        if ! test_mtime "$fileage" "$mtime"; then
            return
        fi
    fi

    if [[ -n "$cnewer" ]]; then
        if ! test_cnewer "$entry" "$cnewer"; then
            return
        fi
    fi

    if [[ -n "$regex" && ! "$filepath" =~ $regex ]]; then
        return
    fi

    echo "$entry"
}

find_files() {
    local current_dir=$1
    
    for entry in "$current_dir"/*; do
        if [[ -d "$entry" ]]; then
            check_and_print_entry "$entry"
            find_files "$entry"
            continue
        fi

        check_and_print_entry "$entry"
    done
}

# Processa cada diretório
for directory in "${directories[@]}"; do
    if [[ ! -d "$directory" ]]; then
        echo "find: ‘$directory’: No such file or directory"
        continue
    fi

    # Checa se o próprio diretório deve ser printado
    check_and_print_entry "$directory"

    # Inicia a busca no diretório
    find_files "$directory"
done
