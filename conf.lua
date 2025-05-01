local love = require("love")

function love.conf(app)
    app.window.width = 702
    app.window.height = 702

    app.window.title = "Minesweeper"
    app.window.icon = "assets/img/gameicon.png"
end