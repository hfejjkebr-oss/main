const express = require("express");
const { createClient } = require("@supabase/supabase-js");

const app = express();
app.use(express.json({ limit: "1mb" }));

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
);

const BOT_TOKEN = process.env.BOT_TOKEN;

app.get("/", (req, res) => {
    res.status(403).send(`
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

app.get("/api/status", (req, res) => {
    res.json({ success: true, name: "Zero Hub API", status: "Online" });
});

// ดึงสคริปต์สำหรับ Loader
app.get("/api/script/:script_id", async (req, res) => {
    const { data, error } = await supabase
        .from("scripts")
        .select("name, content, version")
        .eq("script_id", req.params.script_id)
        .single();

    if (error || !data) {
        return res.status(404).send("-- Script not found");
    }

    res.type("text/plain").send(data.content);
});

// ตรวจสอบ Token สำหรับคำสั่งจัดการสคริปต์
function authorizeBot(req, res, next) {
    if (!BOT_TOKEN || req.headers.authorization !== `Bearer ${BOT_TOKEN}`) {
        return res.status(401).json({ error: "Unauthorized" });
    }
    next();
}

// เพิ่มสคริปต์
app.post("/api/scripts", authorizeBot, async (req, res) => {
    const { name, script_id, content } = req.body;

    if (!name || !script_id || typeof content !== "string") {
        return res.status(400).json({ error: "Missing name, script_id or content" });
    }

    const { data, error } = await supabase
        .from("scripts")
        .insert({ name, script_id, content })
        .select("id, name, script_id, version")
        .single();

    if (error) return res.status(400).json({ error: error.message });
    res.status(201).json({ success: true, script: data });
});

// แก้ไขสคริปต์
app.put("/api/scripts/:script_id", authorizeBot, async (req, res) => {
    const { name, content } = req.body;
    const updates = {};

    if (typeof name === "string") updates.name = name;
    if (typeof content === "string") {
        updates.content = content;
        updates.version = undefined;
    }

    if (Object.keys(updates).length === 0) {
        return res.status(400).json({ error: "No updates provided" });
    }

    const { data: old } = await supabase
        .from("scripts")
        .select("version")
        .eq("script_id", req.params.script_id)
        .maybeSingle();

    if (!old) return res.status(404).json({ error: "Script not found" });

    if (typeof content === "string") updates.version = old.version + 1;

    const { data, error } = await supabase
        .from("scripts")
        .update(updates)
        .eq("script_id", req.params.script_id)
        .select("id, name, script_id, version")
        .single();

    if (error) return res.status(400).json({ error: error.message });
    res.json({ success: true, script: data });
});

// แสดงรายการสคริปต์
app.get("/api/scripts", authorizeBot, async (req, res) => {
    const { data, error } = await supabase
        .from("scripts")
        .select("name, script_id, version, created_at, updated_at")
        .order("created_at", { ascending: false });

    if (error) return res.status(500).json({ error: error.message });
    res.json({ success: true, scripts: data });
});

// ลบสคริปต์
app.delete("/api/scripts/:script_id", authorizeBot, async (req, res) => {
    const { error } = await supabase
        .from("scripts")
        .delete()
        .eq("script_id", req.params.script_id);

    if (error) return res.status(500).json({ error: error.message });
    res.json({ success: true });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
    console.log("Zero Hub API started on port " + PORT);
});
