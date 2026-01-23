hs.window.animationDuration = 0

local function tileCurrentSpaceAllWindows()
	local maxWidth = 550
	local includeDialogs = false

	local front = hs.window.frontmostWindow()
	local screen = (front and front:screen()) or hs.screen.mainScreen()
	local frame = screen:frame()

	local wins = hs.window.visibleWindows()
	local targets = {}
	for _, w in ipairs(wins) do
		if w:screen() == screen and (w:isStandard() or (includeDialogs and w:role() == "AXWindow")) then
			table.insert(targets, w)
		end
	end

	local n = #targets
	if n == 0 then
		hs.alert.show("No windows to tile")
		return
	end

	-- 基本は等分。ただし maxWidth を超えない
	local wEqual = math.floor(frame.w / n)
	local w = math.min(wEqual, maxWidth)

	-- 右寄せ開始位置（余りが出たら左側に余白、右に詰める）
	local totalW = w * n
	local x0 = frame.x + (frame.w - totalW)

	-- 念のため、等分幅の方が小さい（=ウィンドウが多くて細い）場合は等分を優先
	-- （この場合は totalW が frame.w になるので x0 は frame.x になる）
	if wEqual < w then
		w = wEqual
		totalW = w * n
		x0 = frame.x + (frame.w - totalW)
	end

	-- 最後の1枚で端数を吸収（右端ピッタリ）
	for i, win in ipairs(targets) do
		local x = x0 + (i - 1) * w
		local ww = (i == n) and (frame.x + frame.w - x) or w
		win:setFrame({ x = x, y = frame.y, w = ww, h = frame.h })
	end
end

-- ctrl + alt + ↓
hs.hotkey.bind({ "ctrl", "alt" }, "down", tileCurrentSpaceAllWindows)
