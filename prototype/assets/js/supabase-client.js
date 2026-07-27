// Shared Supabase client for the eGovLualhati prototype (buildless, CDN import).
// Fill in your project URL + anon key after creating the Supabase project.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

export const SUPABASE_URL = 'https://pjevutciiwusvfmaooom.supabase.co';
export const SUPABASE_ANON_KEY = 'sb_publishable_5hZIWJqcsoTrJfdCKw40kg_QppyOu3D';

// The active session: login (SSO or OTP) stores the matched users.id here.
// No hardcoded fallback — pages guard with requireSession() (see session.js).
export const CURRENT_USER_ID = localStorage.getItem('session_user_id');

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
