const express = require("express");
const { createClient } = require("@supabase/supabase-js");

const app = express();
app.use(express.json({ limit: "1mb" }));

const PORT = process.env.PORT || 3000;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const BOT_TOKEN = process.env.BOT_TOKEN;

let supabase = null;

if (SUPABASE_URL && SUPABASE_KEY) {
    supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
}

// หน้าแรก
app.get("/", (req, res) => {
    res.status(403).send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Zero Hub</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
        </head>
        <body style="background:#0a0a0a;color:#ff3333;text-align:center;font-family:Arial;padding-top:100px">
            <h1>Zero Hub</h1>
            <h2>Access Denied</h2>
        </body>
        </html>
    `);
});

// ตรวจสอบสถานะ API
app.get("/api/status", (req, res) => {
    res.json({
        success: true,
        name: "Zero Hub API",
        status: "Online"
    });
});

// ตรวจสอบการเชื่อมต่อฐานข้อมูล
app.get("/api/db-status", async (req, res) => {
    if (!supabase) {
        return res.status(503).json({
            success: false,
            database: "Not configured"
        });
    }

    try {
        const { error } = await supabase
            .from("scripts")
            .select("id")
            .limit(1);

        if (error) {
            console.error("Database check failed:", error.message);

            return res.status(500).json({
                success: false,
                database: "Error",
                message: error.message,
                code: error.code
            });
        }

        return res.json({
            success: true,
            database: "Connected",
            table: "scripts"
        });
    } catch (error) {
        console.error("Database check exception:", error.message);

        return res.status(500).json({
            success: false,
            database: "Error"
        });
    }
});

// ตรวจสอบ Token ของ Discord Bot
function authorizeBot(req, res, next) {
    if (!BOT_TOKEN) {
        return res.status(503).json({
            success: false,
            error: "Bot authentication is not configured"
        });
    }

    if (req.headers.authorization !== `Bearer ${BOT_TOKEN}`) {
        return res.status(401).json({
            success: false,
            error: "Unauthorized"
        });
    }

    next();
}

// ดึงเนื้อหาสคริปต์ด้วย Script ID
app.get("/api/script/:script_id", async (req, res) => {
    if (!supabase) {
        return res.status(503)
            .type("text/plain")
            .send("-- Zero Hub API is not configured");
    }

    try {
        const { data, error } = await supabase
            .from("scripts")
            .select("content")
            .eq("script_id", req.params.script_id)
            .maybeSingle();

        if (error) {
            console.error("Get script failed:", error.message);

            return res.status(500)
                .type("text/plain")
                .send("-- Failed to retrieve script");
        }

        if (!data) {
            return res.status(404)
                .type("text/plain")
                .send("-- Script not found");
        }

        return res.type("text/plain").send(data.content);
    } catch (error) {
        console.error("Get script exception:", error.message);

        return res.status(500)
            .type("text/plain")
            .send("-- Internal server error");
    }
});

// เพิ่มสคริปต์
app.post("/api/scripts", authorizeBot, async (req, res) => {
    if (!supabase) {
        return res.status(503).json({
            success: false,
            error: "Database is not configured"
        });
    }

    const { name, script_id, content } = req.body;

    if (
        typeof name !== "string" ||
        !name.trim() ||
        typeof script_id !== "string" ||
        !/^[a-zA-Z0-9_-]{1,100}$/.test(script_id) ||
        typeof content !== "string" ||
        !content.trim()
    ) {
        return res.status(400).json({
            success: false,
            error: "Invalid name, script_id or content"
        });
    }

    try {
        const { data, error } = await supabase
            .from("scripts")
            .insert({
                name: name.trim(),
                script_id,
                content,
                version: 1
            })
            .select("id, name, script_id, version")
            .single();

        if (error) {
            console.error("Add script failed:", error.message);

            return res.status(400).json({
                success: false,
                error: error.code === "23505"
                    ? "script_id already exists"
                    : "Failed to add script"
            });
        }

        return res.status(201).json({
            success: true,
            script: data
        });
    } catch (error) {
        console.error("Add script exception:", error.message);

        return res.status(500).json({
            success: false,
            error: "Internal server error"
        });
    }
});

// แสดงรายการสคริปต์
app.get("/api/scripts", authorizeBot, async (req, res) => {
    if (!supabase) {
        return res.status(503).json({
            success: false,
            error: "Database is not configured"
        });
    }

    try {
        const { data, error } = await supabase
            .from("scripts")
            .select("name, script_id, version, created_at, updated_at")
            .order("created_at", { ascending: false });

        if (error) {
            console.error("List scripts failed:", error.message);

            return res.status(500).json({
                success: false,
                error: "Failed to list scripts"
            });
        }

        return res.json({
            success: true,
            scripts: data
        });
    } catch (error) {
        console.error("List scripts exception:", error.message);

        return res.status(500).json({
            success: false,
            error: "Internal server error"
        });
    }
});

// แก้ไขสคริปต์
app.put("/api/scripts/:script_id", authorizeBot, async (req, res) => {
    if (!supabase) {
        return res.status(503).json({
            success: false,
            error: "Database is not configured"
        });
    }

    const { name, content } = req.body;
    const updates = {};

    if (typeof name === "string" && name.trim()) {
        updates.name = name.trim();
    }

    if (typeof content === "string" && content.trim()) {
        updates.content = content;
    }

    if (Object.keys(updates).length === 0) {
        return res.status(400).json({
            success: false,
            error: "Provide a valid name or content"
        });
    }

    try {
        const { data: oldScript, error: findError } = await supabase
            .from("scripts")
            .select("version")
            .eq("script_id", req.params.script_id)
            .maybeSingle();

        if (findError) {
            console.error("Find script failed:", findError.message);

            return res.status(500).json({
                success: false,
                error: "Failed to find script"
            });
        }

        if (!oldScript) {
            return res.status(404).json({
                success: false,
                error: "Script not found"
            });
        }

        if (typeof content === "string" && content.trim()) {
            updates.version = oldScript.version + 1;
        }

        updates.updated_at = new Date().toISOString();

        const { data, error } = await supabase
            .from("scripts")
            .update(updates)
            .eq("script_id", req.params.script_id)
            .select("name, script_id, version, updated_at")
            .single();

        if (error) {
            console.error("Update script failed:", error.message);

            return res.status(500).json({
                success: false,
                error: "Failed to update script"
            });
        }

        return res.json({
            success: true,
            script: data
        });
    } catch (error) {
        console.error("Update script exception:", error.message);

        return res.status(500).json({
            success: false,
            error: "Internal server error"
        });
    }
});

// ลบสคริปต์
app.delete("/api/scripts/:script_id", authorizeBot, async (req, res) => {
    if (!supabase) {
        return res.status(503).json({
            success: false,
            error: "Database is not configured"
        });
    }

    try {
        const { data, error } = await supabase
            .from("scripts")
            .delete()
            .eq("script_id", req.params.script_id)
            .select("script_id");

        if (error) {
            console.error("Delete script failed:", error.message);

            return res.status(500).json({
                success: false,
                error: "Failed to delete script"
            });
        }

        if (!data || data.length === 0) {
            return res.status(404).json({
                success: false,
                error: "Script not found"
            });
        }

        return res.json({
            success: true,
            deleted: req.params.script_id
        });
    } catch (error) {
        console.error("Delete script exception:", error.message);

        return res.status(500).json({
            success: false,
            error: "Internal server error"
        });
    }
});

// เริ่ม API
app.listen(PORT, "0.0.0.0", () => {
    console.log("Zero Hub API started on port " + PORT);
});
