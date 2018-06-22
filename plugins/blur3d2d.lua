PLUGIN.name = "3D2D Blur Library"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "Plugin for Developers."

nut.blur3d2d = nut.blur3d2d or {}
nut.blur3d2d.list = nut.blur3d2d.list or {}

-- for easy managements
function nut.blur3d2d.add(id, pos, ang, scale, callback)
	if (id and pos and ang and scale and callback) then
		nut.blur3d2d.list[id] = {
			pos = pos, 
			ang = ang,
			scale = scale,
			callback = callback,
			draw = true,
		}
	end
end

-- remove the screen from the rendering list completely.
function nut.blur3d2d.remove(id)
	if (id and nut.blur3d2d.list[id]) then
		nut.blur3d2d.list[id] = nil
	end
end

-- pause drawing the screen. does not removes the info from the table.
function nut.blur3d2d.pause(id)
	if (id and nut.blur3d2d.list[id]) then
		nut.blur3d2d.list[id].draw = false
	end
end

-- start drawing the screen again.
function nut.blur3d2d.resume(id)
	if (id and nut.blur3d2d.list[id]) then
		nut.blur3d2d.list[id].draw = true
	end
end

function nut.blur3d2d.get(id)
	return nut.blur3d2d.list[id]
end

function PLUGIN:PostDrawTranslucentRenderables()
	render.ClearStencil()
	render.SetStencilEnable(true)

	-- for avoid conflict with poorly written stencil badbois
	render.SetStencilWriteMask(99)
	render.SetStencilTestMask(99)
	render.SetStencilFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
	render.SetStencilReferenceValue(1)

	-- I had to change this because I don't want to make draw post process compute run by O(n) 
	if (table.Count(nut.blur3d2d.list) > 0) then
		SUPPRESS_FROM_STENCIL = true
			for _, data in pairs(nut.blur3d2d.list) do
				if (data.draw == false) then continue end

				cam.Start3D2D(data.pos, data.ang, data.scale)
					data.callback()
				cam.End3D2D()
			end

			render.SetStencilReferenceValue(2)
			render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
			render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
			render.SetStencilReferenceValue(1)
			cam.Start2D()
				nut.util.drawBlurAt(0, 0, ScrW(), ScrH(), nut.blur3d2d.amount, nut.blur3d2d.passes)
			cam.End2D()
			render.SetStencilEnable( false )

			for _, data in pairs(nut.blur3d2d.list) do
				if (data.draw == false) then continue end

				cam.Start3D2D(data.pos, data.ang, data.scale)
					data.callback(true)
				cam.End3D2D()
			end
		SUPPRESS_FROM_STENCIL = nil
	end
end