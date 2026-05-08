import dotenv from "dotenv";
import { createClient } from "@supabase/supabase-js";

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const anonKey = process.env.SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
    console.warn("Supabase service credentials are not configured.");
}

if (!supabaseUrl || !anonKey) {
    console.warn("Supabase auth credentials are not configured.");
}

export const supabaseAdmin = createClient(
    supabaseUrl || "http://localhost",
    serviceRoleKey || "missing-service-role-key",
    {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    }
);

export const supabaseAuth = createClient(
    supabaseUrl || "http://localhost",
    anonKey || "missing-anon-key",
    {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    }
);
