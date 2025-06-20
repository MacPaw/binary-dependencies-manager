extension String {
    var black: String {
        "\u{001B}[30m\(self)\u{001B}[0m"
    }

    var red: String {
        "\u{001B}[31m\(self)\u{001B}[0m"
    }

    var green: String {
        "\u{001B}[32m\(self)\u{001B}[0m"
    }

    var yellow: String {
        "\u{001B}[33m\(self)\u{001B}[0m"
    }

    var blue: String {
        "\u{001B}[34m\(self)\u{001B}[0m"
    }

    var magenta: String {
        "\u{001B}[35m\(self)\u{001B}[0m"
    }

    var cyan: String {
        "\u{001B}[36m\(self)\u{001B}[0m"
    }

    var gray: String {
        "\u{001B}[37m\(self)\u{001B}[0m"
    }

    var bg_black: String {
        "\u{001B}[40m\(self)\u{001B}[0m"
    }

    var bg_red: String {
        "\u{001B}[41m\(self)\u{001B}[0m"
    }

    var bg_green: String {
        "\u{001B}[42m\(self)\u{001B}[0m"
    }

    var bg_brown: String {
        "\u{001B}[43m\(self)\u{001B}[0m"
    }

    var bg_blue: String {
        "\u{001B}[44m\(self)\u{001B}[0m"
    }

    var bg_magenta: String {
        "\u{001B}[45m\(self)\u{001B}[0m"
    }

    var bg_cyan: String {
        "\u{001B}[46m\(self)\u{001B}[0m"
    }

    var bg_gray: String {
        "\u{001B}[47m\(self)\u{001B}[0m"
    }

    var bold: String {
        "\u{001B}[1m\(self)\u{001B}[22m"
    }

    var italic: String {
        "\u{001B}[3m\(self)\u{001B}[23m"
    }

    var underline: String {
        "\u{001B}[4m\(self)\u{001B}[24m"
    }

    var blink: String {
        "\u{001B}[5m\(self)\u{001B}[25m"
    }

    var reverse_color: String {
        "\u{001B}[7m\(self)\u{001B}[27m"
    }
}
