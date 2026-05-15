import dotenv from "dotenv";
import { createClient } from "@supabase/supabase-js";
import { logWarn } from "../utils/logger.js";

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const anonKey = process.env.SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
    logWarn("missing_supabase_service_credentials");
}

if (!supabaseUrl || !anonKey) {
    logWarn("missing_supabase_auth_credentials");
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
