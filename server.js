const express = require("express");
const { createClient } = require("@supabase/supabase-js");

const app = express();
const PORT = process.env.PORT || 3000;

// ==========================================
// CONFIG
// ==========================================

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY =
    process.env.SUPABASE_SERVICE_ROLE_KEY;
const BOT_TOKEN = process.env.BOT_TOKEN;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !BOT_TOKEN) {
    throw new Error(
        "Missing environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, BOT_TOKEN"
    );
}

const supabase = createClient(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY
);

app.use(express.json({ limit: "2mb" }));

// ==========================================
// HELPERS
// ==========================================

function requireBotToken(req, res, next) {
    const auth = req.headers.authorization || "";
    const expected = `Bearer ${BOT_TOKEN}`;

    if (auth !== expected) {
        return res.status(401).json({
            success: false,
            error: "Unauthorized"
        });
    }

    next();
}

function validScriptId(scriptId) {
    return (
        typeof scriptId === "string" &&
        /^[a-zA-Z0-9_-]{1,100}$/.test(scriptId)
    );
}

function validScriptContent(content) {
    return (
        typeof content === "string" &&
        content.trim().length > 0 &&
        Buffer.byteLength(content, "utf8") <= 1_000_000
    );
}

// ==========================================
// HOME
// ==========================================

app.get("/", (req, res) => {
    res.status(200).type("text/plain").send(
        "Zero Hub API is running"
    );
});

// ==========================================
// STATUS
// ==========================================

app.get("/api/status", (req, res) => {
    res.json({
        success: true,
        service: "Zero Hub API",
        status: "online"
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
                database: "Error",
                error: error.message
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
            database: "Error"
        });
    }
});

// ==========================================
// PUBLIC SCRIPT ROUTE
// ส่งโค้ด Lua ดิบ ๆ สำหรับ Loadstring
// ==========================================

app.get("/api/script/:script_id", async (req, res) => {
    const { script_id } = req.params;

    if (!validScriptId(script_id)) {
        return res.status(400)
            .type("text/plain")
            .send("-- Invalid script ID");
    }

    try {
        const { data, error } = await supabase
            .from("scripts")
            .select("content")
            .eq("script_id", script_id)
            .single();

        if (error || !data) {
            return res.status(404)
                .type("text/plain")
                .send("-- Script not found");
        }

        res.set("Cache-Control", "no-store");
        res.type("text/plain").send(data.content);

    } catch (error) {
        console.error("Script fetch error:", error.message);

        res.status(500)
            .type("text/plain")
            .send("-- Internal server error");
    }
});

// ==========================================
// ADD SCRIPT
// ==========================================

app.post(
    "/api/scripts",
    requireBotToken,
    async (req, res) => {
        const { name, script_id, content } = req.body || {};

        if (
            typeof name !== "string" ||
            !name.trim() ||
            name.length > 100
        ) {
            return res.status(400).json({
                success: false,
                error: "Invalid script name"
            });
        }

        if (!validScriptId(script_id)) {
            return res.status(400).json({
                success: false,
                error: "Invalid script_id"
            });
        }

        if (!validScriptContent(content)) {
            return res.status(400).json({
                success: false,
                error: "Invalid or empty script content"
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
                .select()
                .single();

            if (error) {
                if (error.code === "23505") {
                    return res.status(409).json({
                        success: false,
                        error: "Script ID already exists"
                    });
                }

                throw error;
            }

            res.status(201).json({
                success: true,
                script: data,
                loadstring:
                    `loadstring(game:HttpGet("${process.env.PUBLIC_API_URL || "https://zero-hub-api.onrender.com"}/api/script/${script_id}"))()`
            });

        } catch (error) {
            console.error("Add script error:", error.message);

            res.status(500).json({
                success: false,
                error: "Failed to add script"
            });
        }
    }
);

// ==========================================
// LIST SCRIPTS
// ==========================================

app.get(
    "/api/scripts",
    requireBotToken,
    async (req, res) => {
        try {
            const { data, error } = await supabase
                .from("scripts")
                .select(
                    "id, name, script_id, version, created_at, updated_at"
                )
                .order("created_at", { ascending: false });

            if (error) {
                throw error;
            }

            res.json({
                success: true,
                scripts: data || []
            });

        } catch (error) {
            console.error("List scripts error:", error.message);

            res.status(500).json({
                success: false,
                error: "Failed to list scripts"
            });
        }
    }
);

// ==========================================
// UPDATE SCRIPT
// ==========================================

app.put(
    "/api/scripts/:script_id",
    requireBotToken,
    async (req, res) => {
        const { script_id } = req.params;
        const { content, name } = req.body || {};

        if (!validScriptId(script_id)) {
            return res.status(400).json({
                success: false,
                error: "Invalid script ID"
            });
        }

        const updates = {};

        if (content !== undefined) {
            if (!validScriptContent(content)) {
                return res.status(400).json({
                    success: false,
                    error: "Invalid or empty script content"
                });
            }

            updates.content = content;
        }

        if (name !== undefined) {
            if (
                typeof name !== "string" ||
                !name.trim() ||
                name.length > 100
            ) {
                return res.status(400).json({
                    success: false,
                    error: "Invalid script name"
                });
            }

            updates.name = name.trim();
        }

        if (Object.keys(updates).length === 0) {
            return res.status(400).json({
                success: false,
                error: "Nothing to update"
            });
        }

        try {
            const { data: existing, error: findError } =
                await supabase
                    .from("scripts")
                    .select("content, version")
                    .eq("script_id", script_id)
                    .single();

            if (findError || !existing) {
                return res.status(404).json({
                    success: false,
                    error: "Script not found"
                });
            }

            if (
                updates.content !== undefined &&
                updates.content !== existing.content
            ) {
                updates.version = (existing.version || 1) + 1;
            }

            updates.updated_at = new Date().toISOString();

            const { data, error } = await supabase
                .from("scripts")
                .update(updates)
                .eq("script_id", script_id)
                .select()
                .single();

            if (error) {
                throw error;
            }

            res.json({
                success: true,
                script: data,
                loadstring:
                    `loadstring(game:HttpGet("${process.env.PUBLIC_API_URL || "https://zero-hub-api.onrender.com"}/api/script/${script_id}"))()`
            });

        } catch (error) {
            console.error("Update script error:", error.message);

            res.status(500).json({
                success: false,
                error: "Failed to update script"
            });
        }
    }
);

// ==========================================
// DELETE SCRIPT
// ==========================================

app.delete(
    "/api/scripts/:script_id",
    requireBotToken,
    async (req, res) => {
        const { script_id } = req.params;

        if (!validScriptId(script_id)) {
            return res.status(400).json({
                success: false,
                error: "Invalid script ID"
            });
        }

        try {
            const { data, error } = await supabase
                .from("scripts")
                .delete()
                .eq("script_id", script_id)
                .select("script_id")
                .single();

            if (error || !data) {
                return res.status(404).json({
                    success: false,
                    error: "Script not found"
                });
            }

            res.json({
                success: true,
                deleted: data.script_id
            });

        } catch (error) {
            console.error("Delete script error:", error.message);

            res.status(500).json({
                success: false,
                error: "Failed to delete script"
            });
        }
    }
);

// ==========================================
// 404
// ==========================================

app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: "Route not found"
    });
});

// ==========================================
// START SERVER
// ==========================================

app.listen(PORT, () => {
    console.log(`Zero Hub API listening on port ${PORT}`);
});
