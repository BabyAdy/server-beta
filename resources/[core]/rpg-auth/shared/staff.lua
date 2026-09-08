-- ===========================================================================
--  Definitia gradelor de staff (partajata).
--  Se incarca si in alte resurse prin:  shared_script '@rpg-auth/shared/staff.lua'
--
--  Coloana `users.staff` (VARCHAR 25) contine slug-ul ('' = civil).
-- ===========================================================================

Staff = {}

-- slug -> { label (afisat), color (#hex), level (ierarhie), shape (icon-staff) }
--  shape = forma iconului afisat in nametag / staff chat. Culoarea iconului e
--  MEREU `color` de mai jos. Fiecare grad are o forma DISTINCTA:
--   owner=coroana (mov), manager=stea (rosu),
--   lead/head/general/junior/trial admin = shield/hexagon/pentagon/diamond/chevron (toate portocaliu),
--   helper=disc plin, trialhelper=inel (ambele verde).
Staff.RANKS = {
    owner        = { label = 'Owner',        color = '#5100ff', level = 100, shape = 'crown'    },
    manager      = { label = 'Manager',      color = '#ff0000', level = 90,  shape = 'star'     },
    leadadmin    = { label = 'Lead Admin',    color = '#ff6a00', level = 80,  shape = 'shield'   },
    headadmin    = { label = 'Head Admin',    color = '#ff6a00', level = 70,  shape = 'hexagon'  },
    generaladmin = { label = 'General Admin', color = '#ff6a00', level = 60,  shape = 'pentagon' },
    junioradmin  = { label = 'Junior Admin',  color = '#ff6a00', level = 50,  shape = 'diamond'  },
    trialadmin   = { label = 'Trial Admin',   color = '#ff6a00', level = 40,  shape = 'chevron'  },
    helper       = { label = 'Helper',       color = '#37ff00', level = 20,  shape = 'disc'     },
    trialhelper  = { label = 'Trial Helper',  color = '#37ff00', level = 10,  shape = 'ring'     },
}

-- markup SVG (interior) pentru fiecare forma. NUI-ul il pune intr-un
-- <svg viewBox="0 0 24 24" style="color: <culoarea gradului>"> (fill/stroke = currentColor).
Staff.ICON_SVG = {
    crown    = '<path fill="currentColor" d="M2 8l4.5 3L12 4l5.5 7L22 8l-2 12H4L2 8z"/>',
    star     = '<path fill="currentColor" d="M12 2l2.9 6.26 6.85.83-5.05 4.68 1.35 6.76L12 17.9 5.95 21.5l1.35-6.76L2.25 9.09l6.85-.83L12 2z"/>',
    shield   = '<path fill="currentColor" d="M12 2l8 3v6c0 5.05-3.4 8.9-8 11-4.6-2.1-8-5.95-8-11V5l8-3z"/>',
    hexagon  = '<path fill="currentColor" d="M8 3h8l4 9-4 9H8l-4-9 4-9z"/>',
    pentagon = '<path fill="currentColor" d="M12 2l9.5 6.9-3.63 11.1H6.13L2.5 8.9 12 2z"/>',
    diamond  = '<path fill="currentColor" d="M12 2l10 10-10 10L2 12 12 2z"/>',
    chevron  = '<path fill="currentColor" d="M12 3l9 8-3.1 3L12 12.4 6.1 14 3 11l9-8z"/>',
    disc     = '<circle cx="12" cy="12" r="9" fill="currentColor"/>',
    ring     = '<circle cx="12" cy="12" r="8" fill="none" stroke="currentColor" stroke-width="4"/>',
}

-- praguri folosite de comenzi
Staff.MIN_ADMIN_CHAT   = 'trialadmin'   -- /a
Staff.MIN_HELPER_CHAT  = 'trialhelper'  -- /hc
Staff.MIN_GLOBAL_CHAT  = 'trialadmin'   -- /o  (anunt global)
Staff.MIN_MANAGE_STAFF = 'manager'      -- /setstaff, /removestaff

-- culoare STANDARD pentru mesajele de chat vizibile DOAR staff-ului
-- (ex. /give, /agl, /debugsec...) -> mereu rosu, ca sa nu se mai specifice de fiecare data.
Staff.BROADCAST_COLOR = '#ff5555'

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

function Staff.shape(slug)
    local r = slug and Staff.RANKS[slug]
    return r and r.shape or nil
end

-- markup SVG (interior) al iconului de grad, sau nil daca gradul nu exista
function Staff.iconSvg(slug)
    local sh = Staff.shape(slug)
    return sh and Staff.ICON_SVG[sh] or nil
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
