-- Keys for vendor messages.
VENDOR_WELCOME = 1
VENDOR_LEAVE = 2
VENDOR_NOTRADE = 3

-- Keys for item information.
VENDOR_PRICE = 1
VENDOR_STOCK = 2
VENDOR_MODE = 3
VENDOR_MAXSTOCK = 4

-- Sell and buy the item.
VENDOR_SELLANDBUY = 1
-- Only sell the item to the player.
VENDOR_SELLONLY = 2
-- Only buy the item from the player.
VENDOR_BUYONLY = 3

VENDOR_TEXT = {}
VENDOR_TEXT[VENDOR_SELLANDBUY] = "vendorBoth"
VENDOR_TEXT[VENDOR_BUYONLY] = "vendorBuy"
VENDOR_TEXT[VENDOR_SELLONLY] = "vendorSell"
