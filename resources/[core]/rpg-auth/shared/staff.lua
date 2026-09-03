-- ===========================================================================
--  Definitia gradelor de staff (partajata).
--  Se incarca si in alte resurse prin:  shared_script '@rpg-auth/shared/staff.lua'
--
--  Coloana `users.staff` (VARCHAR 25) contine slug-ul ('' = civil).
-- ===========================================================================

Staff = {}

-- slug -> { label (afisat), color (#hex), level (ierarhie) }
Staff.RANKS = {
    owner        = { label = 'Owner',        color = '#5100ff', level = 100 },
    manager      = { label = 'Manager',      color = '#ff0000', level = 90  },
    leadadmin    = { label = 'Lead Admin',    color = '#ff6a00', level = 80  },
    headadmin    = { label = 'Head Admin',    color = '#ff6a00', level = 70  },
    generaladmin = { label = 'General Admin', color = '#ff6a00', level = 60  },
    junioradmin  = { label = 'Junior Admin',  color = '#ff6a00', level = 50  },
    trialadmin   = { label = 'Trial Admin',   color = '#ff6a00', level = 40  },
    helper       = { label = 'Helper',       color = '#37ff00', level = 20  },
    trialhelper  = { label = 'Trial Helper',  color = '#37ff00', level = 10  },
}

-- praguri folosite de comenzi
Staff.MIN_ADMIN_CHAT   = 'trialadmin'   -- /a
Staff.MIN_HELPER_CHAT  = 'trialhelper'  -- /hc
Staff.MIN_MANAGE_STAFF = 'manager'      -- /setstaff, /removestaff

function Staff.exists(slug)
    return slug ~= nil and slug ~= '' and Staff.RANKS[slug] ~= nil
end

function Staff.level(slug)
    local r = slug and Staff.RANKS[slug]
    return r and r.level or 0
end

function Staff.label(slug)
    local r = slug and Staff.RANKS[slug]
    return r and r.label or 'Civil'
end

function Staff.color(slug)
    local r = slug and Staff.RANKS[slug]
    return r and r.color or '#9aa0aa'
end

function Staff.atLeast(slug, minSlug)
    return Staff.level(slug) >= Staff.level(minSlug)
end

function Staff.isStaff(slug)
    return Staff.level(slug) > 0
end

-- 'admin' daca gradul e din familia admin (level >= trialadmin), altfel 'helper'
function Staff.kind(slug)
    return Staff.level(slug) >= Staff.level('trialadmin') and 'admin' or 'helper'
end
