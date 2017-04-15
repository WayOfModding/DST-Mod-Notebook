require "constants"
require "strings"

STRINGS.DEBUG = {
    -- Controls: 
    -- Must match the Control enum in DontStarveInputHandler.h
    -- Must match STRINGS.UI.CONTROLSSCREEN.CONTROLS
    CONTROLS = {
        -- player action controls
        [0] = "CONTROL_PRIMARY(0)",
        [1] = "CONTROL_SECONDARY(1)",
        [2] = "CONTROL_ATTACK(2)",
        [3] = "CONTROL_INSPECT(3)",
        [4] = "CONTROL_ACTION(4)",

        -- player movement controls
        [5] = "CONTROL_MOVE_UP(5)",
        [6] = "CONTROL_MOVE_DOWN(6)",
        [7] = "CONTROL_MOVE_LEFT(7)",
        [8] = "CONTROL_MOVE_RIGHT(8)",

        -- view controls
        [9] = "CONTROL_ZOOM_IN(9)",
        [10] = "CONTROL_ZOOM_OUT(10)",
        [11] = "CONTROL_ROTATE_LEFT(11)",
        [12] = "CONTROL_ROTATE_RIGHT(12)",


        -- player movement controls
        [13] = "CONTROL_PAUSE(13)",
        [14] = "CONTROL_MAP(14)",
        [15] = "CONTROL_INV_1(15)",
        [16] = "CONTROL_INV_2(16)",
        [17] = "CONTROL_INV_3(17)",
        [18] = "CONTROL_INV_4(18)",
        [19] = "CONTROL_INV_5(19)",
        [20] = "CONTROL_INV_6(20)",
        [21] = "CONTROL_INV_7(21)",
        [22] = "CONTROL_INV_8(22)",
        [23] = "CONTROL_INV_9(23)",
        [24] = "CONTROL_INV_10(24)",

        [25] = "CONTROL_FOCUS_UP(25)",
        [26] = "CONTROL_FOCUS_DOWN(26)",
        [27] = "CONTROL_FOCUS_LEFT(27)",
        [28] = "CONTROL_FOCUS_RIGHT(28)",

        [29] = "CONTROL_ACCEPT(29)",
        [30] = "CONTROL_CANCEL(30)",
        [31] = "CONTROL_SCROLLBACK(31)",
        [32] = "CONTROL_SCROLLFWD(32)",

        [33] = "CONTROL_PREVVALUE(33)",
        [34] = "CONTROL_NEXTVALUE(34)",

        [35] = "CONTROL_SPLITSTACK(35)",
        [36] = "CONTROL_TRADEITEM(36)",
        [37] = "CONTROL_TRADESTACK(37)",
        [38] = "CONTROL_FORCE_INSPECT(38)",
        [39] = "CONTROL_FORCE_ATTACK(39)",
        [40] = "CONTROL_FORCE_TRADE(40)",
        [41] = "CONTROL_FORCE_STACK(41)",

        [42] = "CONTROL_OPEN_DEBUG_CONSOLE(42)",
        [43] = "CONTROL_TOGGLE_LOG(43)",
        [44] = "CONTROL_TOGGLE_DEBUGRENDER(44)",

        [45] = "CONTROL_OPEN_INVENTORY(45)",
        [46] = "CONTROL_OPEN_CRAFTING(46)",
        [47] = "CONTROL_INVENTORY_LEFT(47)",
        [48] = "CONTROL_INVENTORY_RIGHT(48)",
        [49] = "CONTROL_INVENTORY_UP(49)",
        [50] = "CONTROL_INVENTORY_DOWN(50)",
        [51] = "CONTROL_INVENTORY_EXAMINE(51)",
        [52] = "CONTROL_INVENTORY_USEONSELF(52)",
        [53] = "CONTROL_INVENTORY_USEONSCENE(53)",
        [54] = "CONTROL_INVENTORY_DROP(54)",
        [55] = "CONTROL_PUTSTACK(55)",
        [56] = "CONTROL_CONTROLLER_ATTACK(56)",
        [57] = "CONTROL_CONTROLLER_ACTION(57)",
        [58] = "CONTROL_CONTROLLER_ALTACTION(58)",
        [59] = "CONTROL_USE_ITEM_ON_ITEM(59)",

        [60] = "CONTROL_MAP_ZOOM_IN(60)",
        [61] = "CONTROL_MAP_ZOOM_OUT(61)",

        [62] = "CONTROL_OPEN_DEBUG_MENU(62)",

        [63] = "CONTROL_TOGGLE_SAY(63)",
        [64] = "CONTROL_TOGGLE_WHISPER(64)",
        [65] = "CONTROL_TOGGLE_SLASH_COMMAND(65)",
        [66] = "CONTROL_TOGGLE_PLAYER_STATUS(66)",
        [67] = "CONTROL_SHOW_PLAYER_STATUS(67)",

        [68] = "CONTROL_MENU_MISC_1(68)",
        [69] = "CONTROL_MENU_MISC_2(69)",
        [70] = "CONTROL_MENU_MISC_3(70)",
        [71] = "CONTROL_MENU_MISC_4(71)",

        [72] = "CONTROL_INSPECT_SELF(72)",

        [100] = "CONTROL_CUSTOM_START(100)",
    },
};

function _G.GetControlName(constant)
    return STRINGS.DEBUG.CONTROLS[constant] or "Unknown Control(" .. tostring(constant) .. ")"
end