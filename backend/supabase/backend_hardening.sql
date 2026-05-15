do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'profiles_display_name_length') then
        alter table public.profiles
            add constraint profiles_display_name_length
            check (char_length(display_name) <= 100);
    end if;

    if not exists (select 1 from pg_constraint where conname = 'profiles_activity_level_known') then
        alter table public.profiles
            add constraint profiles_activity_level_known
            check (activity_level in ('sedentary', 'light', 'moderate', 'active', 'athlete'));
    end if;

    if not exists (select 1 from pg_constraint where conname = 'custom_foods_client_id_length') then
        alter table public.custom_foods
            add constraint custom_foods_client_id_length
            check (client_id is null or char_length(client_id) between 1 and 128);
    end if;

    if not exists (select 1 from pg_constraint where conname = 'custom_foods_name_length') then
        alter table public.custom_foods
            add constraint custom_foods_name_length
            check (char_length(name) between 1 and 140);
    end if;

    if not exists (select 1 from pg_constraint where conname = 'custom_foods_unit_length') then
        alter table public.custom_foods
            add constraint custom_foods_unit_length
            check (char_length(unit) between 1 and 64);
    end if;

    if not exists (select 1 from pg_constraint where conname = 'custom_foods_calories_range') then
        alter table public.custom_foods
            add constraint custom_foods_calories_range
            check (calories between 0 and 10000);
    end if;

    if not exists (select 1 from pg_constraint where conname = 'custom_foods_macro_ranges') then
        alter table public.custom_foods
            add constraint custom_foods_macro_ranges
            check (protein_g between 0 and 1000 and carbs_g between 0 and 1000 and fat_g between 0 and 1000);
    end if;

    if not exists (select 1 from pg_constraint where conname = 'diary_entries_client_id_length') then
        alter table public.diary_entries
            add constraint diary_entries_client_id_length
            check (client_id is null or char_length(client_id) between 1 and 128);
    end if;

    if not exists (select 1 from pg_constraint where conname = 'diary_entries_food_name_length') then
        alter table public.diary_entries
            add constraint diary_entries_food_name_length
            check (char_length(food_name) between 1 and 140);
    end if;

    if not exists (select 1 from pg_constraint where conname = 'diary_entries_unit_length') then
        alter table public.diary_entries
            add constraint diary_entries_unit_length
            check (char_length(unit) between 1 and 64);
    end if;

    if not exists (select 1 from pg_constraint where conname = 'diary_entries_meal_known') then
        alter table public.diary_entries
            add constraint diary_entries_meal_known
            check (meal in ('Sáng', 'Trưa', 'Snack', 'Tối'));
    end if;

    if not exists (select 1 from pg_constraint where conname = 'diary_entries_calories_range') then
        alter table public.diary_entries
            add constraint diary_entries_calories_range
            check (calories between 0 and 10000);
    end if;

    if not exists (select 1 from pg_constraint where conname = 'diary_entries_macro_ranges') then
        alter table public.diary_entries
            add constraint diary_entries_macro_ranges
            check (protein_g between 0 and 1000 and carbs_g between 0 and 1000 and fat_g between 0 and 1000);
    end if;

    if not exists (select 1 from pg_constraint where conname = 'water_logs_consumed_ml_range') then
        alter table public.water_logs
            add constraint water_logs_consumed_ml_range
            check (consumed_ml between 0 and 10000);
    end if;

    if not exists (select 1 from pg_constraint where conname = 'weight_logs_client_id_length') then
        alter table public.weight_logs
            add constraint weight_logs_client_id_length
            check (client_id is null or char_length(client_id) between 1 and 128);
    end if;
end $$;
