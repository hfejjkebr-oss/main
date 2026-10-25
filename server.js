const express = require("express");

const app = express();
app.use(express.json());

app.get("/", (req, res) => {
    res.status(403).send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Zero Hub</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {
                    background: #0a0a0a;
                    color: #ff3333;
                    font-family: Arial, sans-serif;
                    text-align: center;
                    padding-top: 100px;
                }
            </style>
        </head>
        <body>
            <h1>Zero Hub</h1>
            <h2>Access Denied</h2>
            <p>You are not authorized to access this page.</p>
        </body>
        </html>
    `);
});

app.get("/api/status", (req, res) => {
    res.json({
        success: true,
        name: "Zero Hub API",
        status: "Online"
    });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, "0.0.0.0", () => {
    console.log("Zero Hub API started on port " + PORT);
});
