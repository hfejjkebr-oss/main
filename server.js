const express = require("express");
const { createClient } = require("@supabase/supabase-js");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json({ limit: "2mb" }));

// ==========================================
// ZERO HUB CONFIG
// ==========================================

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY =
    process.env.SUPABASE_SERVICE_ROLE_KEY;

const BOT_TOKEN = process.env.BOT_TOKEN;

const PUBLIC_API_URL =
    process.env.PUBLIC_API_URL ||
    "https://zero-hub-api.onrender.com";

const LOGO_URL =
    "https://cdn.discordapp.com/attachments/1507715904690065611/1563868932857929880/BackgroundEraser_20261022_122239184.png";

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    console.error("Missing Supabase environment variables.");
    process.exit(1);
}

const supabase = createClient(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY
);

// ==========================================
// AUTHENTICATION
// ==========================================

function requireAuth(req, res, next) {
    if (!BOT_TOKEN) {
        return res.status(500).json({
            success: false,
            message: "API authentication is not configured."
        });
    }

    const authHeader = req.headers.authorization;

    if (authHeader !== `Bearer ${BOT_TOKEN}`) {
        return res.status(401).json({
            success: false,
            message: "Unauthorized."
        });
    }

    next();
}

// ==========================================
// ZERO HUB ACCESS DENIED PAGE
// ==========================================

function accessDeniedPage() {
    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="theme-color" content="#080808">

<title>Zero Hub | Access Denied</title>

<style>
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
    background: #080808;
    color: #ffffff;
    font-family: Arial, Helvetica, sans-serif;
}

.container {
    width: 100%;
    max-width: 430px;
    padding: 40px 28px 25px;
    text-align: center;
    background: #101010;
    border: 1px solid #292929;
    border-radius: 18px;
    box-shadow: 0 0 45px rgba(255, 35, 35, 0.07);
}

.logo {
    width: 110px;
    height: 110px;
    margin: 0 auto 22px;
    display: flex;
    align-items: center;
    justify-content: center;
}

.logo img {
    display: block;
    width: 100%;
    height: 100%;
    object-fit: contain;
}

.brand {
    font-size: 27px;
    font-weight: 800;
    letter-spacing: 3px;
}

.brand span {
    color: #ff3535;
}

.subtitle {
    margin-top: 10px;
    color: #777777;
    font-size: 10px;
    letter-spacing: 3px;
}

.divider {
    width: 42px;
    height: 2px;
    margin: 27px auto;
    background: #ff3535;
}

.status {
    display: inline-block;
    padding: 8px 13px;
    margin-bottom: 20px;
    border: 1px solid #512020;
    border-radius: 7px;
    background: #1d1010;
    color: #ff5757;
    font-size: 10px;
    font-weight: bold;
    letter-spacing: 1.5px;
}

h1 {
    margin-bottom: 13px;
    font-size: 23px;
    font-weight: 700;
}

.description {
    color: #999999;
    font-size: 13px;
    line-height: 1.9;
}

.footer {
    margin-top: 32px;
    padding-top: 19px;
    border-top: 1px solid #262626;
    color: #555555;
    font-size: 10px;
    letter-spacing: 1.5px;
    line-height: 1.8;
}

@media (max-width: 360px) {
    .container {
        padding: 32px 20px 22px;
    }

    .brand {
        font-size: 24px;
    }

    .logo {
        width: 90px;
        height: 90px;
    }
}
</style>
</head>

<body>
    <main class="container">

        <div class="logo">
            <img
                src="${LOGO_URL}"
                alt="Zero Hub Logo"
            >
        </div>

        <div class="brand">
            ZERO <span>HUB</span>
        </div>

        <div class="subtitle">
            SCRIPT PROTECTION SYSTEM
        </div>

        <div class="divider"></div>

        <div class="status">
            403 · ACCESS RESTRICTED
        </div>

        <h1>Access Denied</h1>

        <p class="description">
            You do not have permission to view this
            script's source code.
            <br><br>
            This content is protected by Zero Hub.
        </p>

        <div class="footer">
            ZERO HUB &copy; 2026
            <br>
            ALL RIGHTS RESERVED
        </div>

    </main>
</body>
</html>`;
}

// ==========================================
// HOME
// ==========================================

app.get("/", (req, res) => {
    res.status(200).send("Zero Hub API is running.");
});

// ==========================================
// API STATUS
// ==========================================

app.get("/api/status", (req, res) => {
    res.json({
        success: true,
        name: "Zero Hub API",
        status: "online",
        version: "1.0.0"
    });
});

// ==========================================
// DATABASE STATUS
// ==========================================

app.get("/api/db-status", async (req, res) => {
    try {
        const { error } = await supabase
            .from("scripts")
            .select("id")
            .limit(1);

        if (error) {
            return res.status(500).json({
                success: false,
                database: "Disconnected"
            });
        }

        res.json({
            success: true,
            database: "Connected",
            table: "scripts"
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            database: "Disconnected"
        });
    }
});

// ==========================================
// GET SCRIPT
// Browser: Access Denied page
// Other clients: Lua source
// ==========================================

app.get("/api/script/:script_id", async (req, res) => {
    const { script_id } = req.params;
    const accept = req.get("accept") || "";

    // Show the designed page to browser requests.
    if (accept.includes("text/html")) {
        return res
            .status(403)
            .type("html")
            .send(accessDeniedPage());
    }

    try {
        if (!/^[a-zA-Z0-9_-]{1,100}$/.test(script_id)) {
            return res
                .status(400)
                .type("text/plain")
                .send("-- Invalid script ID");
        }

        const { data, error } = await supabase
            .from("scripts")
            .select("content")
            .eq("script_id", script_id)
            .maybeSingle();

        if (error) {
            console.error("Fetch script error:", error.message);

            return res
                .status(500)
                .type("text/plain")
                .send("-- Failed to fetch script");
        }

        if (!data) {
            return res
                .status(404)
                .type("text/plain")
                .send("-- Script not found");
        }

        res
            .status(200)
            .type("text/plain")
            .send(data.content);

    } catch (error) {
        console.error("Script route error:", error.message);

        res
            .status(500)
            .type("text/plain")
            .send("-- Internal server error");
    }
});

// ==========================================
// ADD SCRIPT
// ==========================================

app.post("/api/scripts", requireAuth, async (req, res) => {
    try {
        const { name, script_id, content } = req.body;

        if (!name || !script_id || !content) {
            return res.status(400).json({
                success: false,
                message: "name, script_id and content are required."
            });
        }

        if (
            typeof script_id !== "string" ||
            !/^[a-zA-Z0-9_-]{1,100}$/.test(script_id)
        ) {
            return res.status(400).json({
                success: false,
                message: "Invalid script_id."
            });
        }

        if (
            typeof content !== "string" ||
            content.length > 1024 * 1024
        ) {
            return res.status(400).json({
                success: false,
                message: "Invalid content or script exceeds 1 MB."
            });
        }

        const { data: existing, error: checkError } = await supabase
            .from("scripts")
            .select("id")
            .eq("script_id", script_id)
            .maybeSingle();

        if (checkError) throw checkError;

        if (existing) {
            return res.status(409).json({
                success: false,
                message: "This script_id already exists."
            });
        }

        const { data, error } = await supabase
            .from("scripts")
            .insert({
                name,
                script_id,
                content,
                version: 1
            })
            .select("id, name, script_id, version, created_at")
            .single();

        if (error) throw error;

        res.status(201).json({
            success: true,
            message: "Script added successfully.",
            script: data,
            loadstring:
                `loadstring(game:HttpGet("${PUBLIC_API_URL}/api/script/${script_id}"))()`
        });

    } catch (error) {
        console.error("Add script error:", error.message);

        res.status(500).json({
            success: false,
            message: "Failed to add script."
        });
    }
});

// ==========================================
// LIST SCRIPTS
// ==========================================

app.get("/api/scripts", requireAuth, async (req, res) => {
    try {
        const { data, error } = await supabase
            .from("scripts")
            .select("id, name, script_id, version, created_at, updated_at")
            .order("created_at", { ascending: false });

        if (error) throw error;

        res.json({
            success: true,
            count: data.length,
            scripts: data
        });

    } catch (error) {
        console.error("List scripts error:", error.message);

        res.status(500).json({
            success: false,
            message: "Failed to list scripts."
        });
    }
});

// ==========================================
// UPDATE SCRIPT
// ==========================================

app.put("/api/scripts/:script_id", requireAuth, async (req, res) => {
    try {
        const { script_id } = req.params;
        const { name, content } = req.body;

        if (!/^[a-zA-Z0-9_-]{1,100}$/.test(script_id)) {
            return res.status(400).json({
                success: false,
                message: "Invalid script_id."
            });
        }

        if (name === undefined && content === undefined) {
            return res.status(400).json({
                success: false,
                message: "Provide name or content to update."
            });
        }

        if (
            content !== undefined &&
            (
                typeof content !== "string" ||
                content.length > 1024 * 1024
            )
        ) {
            return res.status(400).json({
                success: false,
                message: "Invalid content or script exceeds 1 MB."
            });
        }

        if (name !== undefined && typeof name !== "string") {
            return res.status(400).json({
                success: false,
                message: "Invalid name."
            });
        }

        const { data: existing, error: findError } = await supabase
            .from("scripts")
            .select("id, version")
            .eq("script_id", script_id)
            .maybeSingle();

        if (findError) throw findError;

        if (!existing) {
            return res.status(404).json({
                success: false,
                message: "Script not found."
            });
        }

        const updates = {
            updated_at: new Date().toISOString()
        };

        if (name !== undefined) {
            updates.name = name;
        }

        if (content !== undefined) {
            updates.content = content;
            updates.version = (existing.version || 0) + 1;
        }

        const { data, error } = await supabase
            .from("scripts")
            .update(updates)
            .eq("script_id", script_id)
            .select("id, name, script_id, version, updated_at")
            .single();

        if (error) throw error;

        res.json({
            success: true,
            message: "Script updated successfully.",
            script: data
        });

    } catch (error) {
        console.error("Update script error:", error.message);

        res.status(500).json({
            success: false,
            message: "Failed to update script."
        });
    }
});

// ==========================================
// DELETE SCRIPT
// ==========================================

app.delete("/api/scripts/:script_id", requireAuth, async (req, res) => {
    try {
        const { script_id } = req.params;

        if (!/^[a-zA-Z0-9_-]{1,100}$/.test(script_id)) {
            return res.status(400).json({
                success: false,
                message: "Invalid script_id."
            });
        }

        const { data, error } = await supabase
            .from("scripts")
            .delete()
            .eq("script_id", script_id)
            .select("id, name, script_id");

        if (error) throw error;

        if (!data || data.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Script not found."
            });
        }

        res.json({
            success: true,
            message: "Script deleted successfully.",
            script: data[0]
        });

    } catch (error) {
        console.error("Delete script error:", error.message);

        res.status(500).json({
            success: false,
            message: "Failed to delete script."
        });
    }
});

// ==========================================
// 404 HANDLER
// ==========================================

app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: "Endpoint not found."
    });
});

// ==========================================
// START SERVER
// ==========================================

app.listen(PORT, () => {
    console.log(`Zero Hub API running on port ${PORT}`);
});
