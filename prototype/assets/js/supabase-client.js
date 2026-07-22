// Shared Supabase client for the eGovLualhati prototype (buildless, CDN import).
// Fill in your project URL + anon key after creating the Supabase project.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

export const SUPABASE_URL = 'https://ukmznrvlufbjagssxpyu.supabase.co';
export const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVrbXpucnZsdWZiamFnc3N4cHl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2Mzg3NDksImV4cCI6MjEwMDIxNDc0OX0.uLtU5DhEN0NXJ8OVO5lVP6hXQkbrxvEdLCnUV3UzOoY';

// The active session: login (SSO or OTP) stores the matched users.id here.
// No hardcoded fallback — pages guard with requireSession() (see session.js).
export const CURRENT_USER_ID = localStorage.getItem('session_user_id');

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
