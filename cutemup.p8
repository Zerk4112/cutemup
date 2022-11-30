pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- game info and credits

-->8
-- game loop

function _init()
	
	mchunks = {}
	printh('~~~~~~~~PROG INIT~~~~~~')
	menuitem(1,"Toggle Player 2", function() local p2=players[2] p2.pos.x = players[1].pos.x p2.pos.y = players[1].pos.y p2.act=not p2.act end)
	init_scenes()
	ai_steer_spd=0.070
	max_ents=10
	aroutines={}
	drigs = {}
	routines={}
	entities={}
	cament = create_ent({}, -1, {x=0,y=0,w=4,h=4}, _mot, _coll_box)
	-- cament.coll_box = create_coll_box(64, 64, 10, 10, function() end)
	del(drigs, cament.draw_rig)
	del(entities, cament)
	init_players()
	for p in all(players) do clean_ent(p) end
	ents=2
	add(routines, test)
	switch_scene(scenes.stage1, true)
end

function _update60()
	if (current_scene~=nil and current_scene.update~=nil and not scene_switch) current_scene:update()
	manage_routines()
	
end

function _draw()
    cls()
	if (current_scene~=nil and current_scene.draw~=nil) current_scene:draw()
	
	if not cament.moving then
		local ordered={}
		for obj in all(entities) do
			ordered[flr(obj.pos.y)] = ordered[flr(obj.pos.y)] or {} -- ensure table is there
			add(ordered[flr(obj.pos.y)],obj.draw_rig)
		end
		for i=cament.pos.y,cament.pos.y+127 do -- or whatever your min/max Y is
			manage_routines(ordered[i])
		end	
	else
		manage_routines(drigs)
	end
	-- manage_routines(drigs)
	manage_routines(aroutines)
	for e in all(entities) do
		-- if (e.act) draw_coll_box(e.coll_box)
	end
	if (_cls) cls(1)

	print('debug', cament.pos.x,cament.pos.y,14)
	print('entities: '..#entities)
	print('aroutines: '..#aroutines)
	print('routines: '..#routines)
	print('drigs: '..#drigs)
	print(players[1].sprhflip)
	-- print(tostr(players[1].srtn))
	-- print(players[1].sprflip)
	-- print(#aroutines)
	-- print(players[1].mot.dx..","..players[1].mot.dy)
	-- print('camera moving: '..tostr(cament.moving))
	
end

-->8
-- player functions

function init_players()
	if (players~=nil) for p in all(players) do clean_ent(p) end
	players={}

	pstand = {31}
	psstand = {62}
	pfstand = {46}
	pfsstand = {30}

	prun = {18,19,20,21}
	psrun = {58,59,60,61}
	pfrun = {42,43,44,45}
	pfsrun = {26,27,28,29}
	
	for i=0,1 do
		local p = create_ent(prun, i)
		p.chx,p.chy=0,0
		-- p.coll_box = create_coll_box(2, 2, 4, 4, player_collide)
		p.logic = create_timer(function()
			
			if p.mot.dx<-0.1 or p.mot.dy < -0.1 or p.mot.dx > 0.1 or p.mot.dy > 0.1 then
				if p.shooting then
					if p.sprhflip then
						p.sprtab = pfsrun
					else
						p.sprtab = psrun
					end
				else
					if p.sprhflip then
						p.sprtab = pfrun
					else

						p.sprtab = prun
					end
				end
			else
				if p.shooting then
					if p.sprhflip then
						p.sprtab = pfsstand
					else
						p.sprtab = psstand
					end
				else
					if p.sprhflip then
						p.sprtab = pfstand
					else
						p.sprtab = pstand
					end
				end
			end
			
		end,1,true)
		add(routines, p.logic)
		add(players, p)
	end
end

function player_collide(self, e)
	-- if e~=nil then
	-- 	printh('collided with '..e.pid)
	-- else
	-- 	printh('collided with unknown object')
	-- end
end

function create_bullet(_x,_y,_s,_a,_id)
	local dx,dy = cos(_a)*_s,sin(_a)*_s
	local b = create_ent({}, -2, {x=_x,y=_y,w=1,h=1}, {
		dx=dx, --dx
		dy=dy, --dy,
		a=1,
		mspd=_s,
		drg=1,
		ang=_a
	})
	b.behavior = create_timer(function()
		-- update_coll_box(b)
		-- check_collision(b)
		local entshot = false
		move_entity(b)
		local bx,by = b.pos.x,b.pos.y
		local a = aget(_x,_y,bx,by)
		local ddx,ddy = cos(a)*-_s, sin(a)*-_s

		line(bx,by,bx+ddx,by+ddy,6)
		pset(bx,by,10)
		for e in all(entities) do
			if check_pos_collision(bx,by, e.coll_box) then 
				if (e.pid>1 and e.act) clean_ent(e) e.act=false clean_ent(b) sfx(1)
			end
		end
		if b.mot.dx~=dx or b.mot.dy~=dy or off_cam(bx, by) then
			clean_ent(b)
		end
	end,1,true)
	add(aroutines,b.behavior)
	del(drigs,b.draw_rig)
	b.draw_rig=nil
	return b
end

function player_shoot(p)
	p.ps = p.sprflip
	p.psh = p.sprhflip
	local x,y = p.pos.x+3.5,p.pos.y+3.5
	local a = aget(x,y,x+p.mot.dx,y+p.mot.dy)
	local ch = create_timer(function()
		while btn(4, p.pid) do
			local ox = 0
			if (not p.sprflip) ox=7
			x,y = p.pos.x+3.5,p.pos.y+3.5
			dx,dy = cos(a)*10, sin(a)*10
			local nx,ny = x+dx,y+dy
			p.chx,p.chy = nx,ny
			circ(nx,ny,1,10)
			circ(nx,ny,4,8)
			yield()
		end
	end,1) 
	local r = create_timer(function()
		local i=p.shtdelay
		while btn(4, p.pid) do
			local ox = 0
			i+=1
			if i>=p.shtdelay then
				i=0
				if (not p.sprflip) ox=7
				local px,py = p.pos.x+ox, p.pos.y+4
				sfx(0)
				for k=0,2 do -- muzzle flash
					circfill(px, py,3,8)
					circfill(px, py,2,10)
					circfill(px, py,1,7)
					yield()
				end
				create_bullet(p.chx, p.chy,2,aget(p.pos.x+3.5, p.pos.y+3.5,p.chx,p.chy)+rnd(0.015)-rnd(0.015))
				yield()
			end
			yield()
		end
		p.srtn=nil
		p.shooting=false
	end,1) 
	p.srtn=r
	add(aroutines, ch)
	add(aroutines, r)
end

function update_controls(p)
	--when the user tries to move,
	--we only add the acceleration
	--to the current speed.
	local ps = p.shooting
	if p.mot.dy <=0.1 and p.mot.dy >= -0.1 and not ps then
		p.sprhflip = false
	end
	if (btn(0,p.pid)) then
		p.mot.dx-=p.mot.a 
		if (not ps) p.sprflip=true
	end
	if (btn(1,p.pid)) then 
		p.mot.dx+=p.mot.a 
		if (not ps) p.sprflip=false
	end
	if (btn(2,p.pid)) then 
		p.mot.dy-=p.mot.a 
		if (not ps) p.sprhflip=true

	end
	if (btn(3,p.pid)) then 
		if (not ps) p.sprhflip=false
		p.mot.dy+=p.mot.a
	end
	if btn(4, p.pid) then
		p.shooting=true
		if p.srtn == nil then 
			player_shoot(p)
		else
			p.sprflip=p.ps
			p.sprhflip=p.psh
		end
	end
	if (btn(5, p.pid)) printh('x button pressed')
end

function tbl_dump(o)
    if type(o) == 'table' then
        -- printh('parsing table, length: '..#o)
		local h,f='',''
        local s = '{'
        for k,v in pairs(o) do
            -- printh(tostr(k).."/"..type(v))
            if (type(k) == 'number') h='[' f=']'
            s = s .. h..k..f..' = ' .. tbl_dump(v) .. ','
        end
        return s .. '}'
    else
		-- printh(tostr(o).."/"..type(o))
		if (type(o)=="string") return '"'..o..'"'
        return tostr(o)
    end
end

-->8 
-- entity ai functions
function ai__rotate_to_target(e) 
	local t = e.targ
	local ex,ey = e.pos.x+e.pos.w/2, e.pos.y+e.pos.h/2
	local tx,ty = t.pos.x+t.pos.w/2, t.pos.y+t.pos.h/2
	-- angle code credits: https://www.gamedev.net/forums/topic/679527-rotate-towards-a-target-angle/ USER https://www.gamedev.net/draika-the-dragon/
	local aim_ang=oaget(t,e)
	local desiredanglem1=aim_ang-1
	local desiredanglep1=aim_ang+1
	
	local dadiff=abs(aim_ang-e.mot.ang)
	local dam1diff=abs(desiredanglem1-e.mot.ang)
	local dap1diff=abs(desiredanglep1-e.mot.ang)
	local closestuniverse=aim_ang
	closestdifftozero=dadiff
	if dam1diff<closestdifftozero then
		closestdifftozero=dam1diff
		closestuniverse=desiredanglem1
	end
	if dap1diff<closestdifftozero then
		closestdifftozero=dap1diff
		closestuniverse=dam1diff
	end

	
	if closestuniverse>e.mot.ang+ai_steer_spd then
		e.mot.ang+=ai_steer_spd
	elseif closestuniverse<e.mot.ang-ai_steer_spd then
		e.mot.ang-=ai_steer_spd
	end


	if (e.mot.ang>1) e.mot.ang=0
	if (e.mot.ang<0) e.mot.ang=0.999

end

function create_sml_goomba(_x,_y)
	local p = create_ent({71,72,71,70}, ents, {
		x=_x, --x
		y=_y, --y,
		w=7,
		h=7
	})
	p.coll_box=create_coll_box(-1, 5, 9, 5, function()  end)
	p.mot.mspd=0.2
	p.animdelay=15
	-- p.coll_box.coll_callback = function(cb, e) 
	-- 	-- printh(tbl_dump(t))
	-- 	if e.pid <2 then
	-- 		-- printh('touching player')
	-- 	else
	-- 		-- printh('touching other enemy')
	-- 		local tx,ty,ta
	-- 		ta = oaget(p,e)
	-- 		tx = e.pos.x+cos(ta)*8
	-- 		ty = e.pos.y+sin(ta)*8
	-- 		p.pos.x = tx
	-- 		p.pos.y = ty
	-- 	end
	-- end
	p.behavior=create_timer(function()
		update_coll_box(p)
		check_collision(p)
		move_entity(p)
		-- yield()
		-- print(p.mot.dx..","..p.mot.dy, p.pos.x, p.pos.y-6,7)
	end,1,true)
	p.pathing = create_timer(function()
		p.targ=ai__pick_player_target(p)
		ai__rotate_to_target(p)
		-- yield()
		ai__path_to_players(p)
		ai__move_to_target(p)
	end,1,true)
	add(aroutines, p.behavior)
	add(aroutines, p.pathing)
	-- add(entities, p)
	ents+=1
	return p
end

function ai__steer(e, d)
	local sspd = ai_steer_spd
	-- printh(sspd)
	if d==-0.25 then
		e.mot.a=e.mot.oa
		e.mot.ang+=sspd
		yield()
	elseif d==0.25 then
		e.mot.a=e.mot.oa
		e.mot.ang-=sspd
		yield()
	end
	
	if (e.mot.ang>1) e.mot.ang=0
	if (e.mot.ang<0) e.mot.ang=0.999
	yield()

end

function ai__pick_player_target(e)
	local p1, p2 = players[1], players[2]
	local p1d, p2d = dst(e,p1), dst(e,p2)
	local p1a, p2a = p1.act, p2.act
	if (p1a and not p2a) return p1
	if (p2a and not p1a) return p2
	if (p1d<p2d) return p1
	return p2
end

function ai__path_to_players(e)
	local targ = e.targ -- target entity stored in source entity table
	local tang = oaget(e, targ) -- angle from source to target
	local tx, ty -- undefined local variables for temp x and y
	local ang = e.mot.ang -- current path angle of source entity
	local col=9 -- debug path color
	for n=-0.25,0.25, 0.25 do -- draw 3 pixels. One in front, and one on each side
		tx=(e.pos.x+e.pos.w/2)-(cos(ang+n)*6) -- define x for current pixel
		ty=(e.pos.y+e.pos.h/2)-(sin(ang+n)*6) -- define y for current pixel
		-- circfill(tx,ty,1,col)
		yield() -- yield processing back to main loop
		for i, ent in pairs(entities) do -- loop through entities to see if any are colliding with path pixel
			if e.pid ~= ent.pid and ent.pid>1 then -- If the entity is another enemy, then continue
				if check_pos_collision(tx,ty, ent.coll_box) then -- if colliding with another enemy
					if n==0 then -- if colliding enemy is in front, stop moving
						e.mot.a=0
						yield() -- yield processing back to main loop
					end
					ai__steer(e,n) -- steer function to avoid clumping of mobs
					yield() -- yield processing back to main loop
				else
					e.mot.a=e.mot.oa -- if nothing is colliding, reset accelleration back to default. needs refactoring for stats!
				end
			end
		end
		yield() -- yield processing back to main loop
	end
end

function ai__move_to_target(ent)
	ent.mot.dx-=cos(ent.mot.ang)
	ent.mot.dy-=sin(ent.mot.ang)
end

-->8
-- scene functions

function init_scenes()
	_cls = true
	scenes = {
		title={
			init=function()
				add(aroutines,create_timer(function()
					local y=-1
					local flashing,c,s = false, 9,0
					local tm=0
					yields(15)
					while true do
						if (y<68) y+=2.5 
						if y>=68 and stat(54)==-1 then
							-- music(60)
							if (tm<3)tm+=0.1
						end
						hor_wave_print("press 🅾️ /z to start!",21,y,c,tm,t(),1.2) 
						if (btnp(4)) flashing = true
						if flashing then
							c+=0.2
							s+=0.1
							if (s>1.5) tm+=2
							if (s>5) switch_scene(scenes.stage1) music(-1, 1000) break
							if (c>11) c=9
						end
						yield()
					end
				end,1,true))
			end,
			draw=function()
				-- map(32,0,0,0,16,16)
			end
		},
		test_menu={
			init=function()
				add(aroutines,create_timer(function()
					print('hey look a new scene')
				end,1,true))
				music(0)
			end,
			update=function()
				if (btnp(4)) switch_scene(scenes.title) music(-1)
			end
		},
		stage1={
			init=init_stage1,
			draw=draw_stage1,
			update=function()
				-- if (btnp(4)) switch_scene(scenes.test_menu) music(-1)
				update_stage1()
			end
		}
	}
end

function switch_scene(_scene, _t)
	local n=create_timer(function()
		scene_switch=true
		local f,s
		if not _t then
			f,s = scene_fade()
		end
		while s=='suspended' do
			s=costatus(f)
			yield()
		end
		for i=1,#routines do
			deli(routines, 1)
		end
		for i=1,#aroutines do
			deli(aroutines, 1)
		end
		current_scene = _scene
		f,s = scene_fade(true,current_scene.init)
		while s=='suspended' do
			s=costatus(f)
			yield()
		end
	end)
	add(aroutines, n)
end

function scene_fade(_in, _cb)
	local lin = _in or false
	local cb = _cb or false
    local g={}
    local t = create_timer(function()
        for y=0,8 do
            for x=0,8 do
                local c = create_timer(function()

                    local r=0
                    if (lin) r=16 
                    while true do
                        if not lin then
                            r+=0.5
                            if (r>16)r=16
                        else
                            r-=0.5
                            if (r<0)r=0
                        end
                        circfill(cament.pos.x+x*16,cament.pos.y+y*16,r,1)
                        yield()
                    end
                end,1) 
                add(aroutines, c)
                add(g, c)
            end
        end
        yield()
        if (lin) _cls=false 
        yields(31)
        for i, h in pairs(g) do
            del(aroutines, h)
        end
		
        if (not lin) _cls=true
		
		if (cb) cb() scene_switch=false
    end)
    add(aroutines, t)
	return t, costatus(t)
end

-->8
-- animation and draw helpers
function ent_drawing_rig(e)
	local animi = 1
	local animpos = true
	e.prev_tab = e.sprtab
	local rig = create_timer(function()
		local gsp = function()
			local newi = animi
			local negchk = newi-1<1
			local poschk = newi+1>#e.sprtab
			if animpos then
				if poschk then
					if e.animwobble then
						animpos = false
						if (not negchk) newi-=1
					else
						newi=1
					end
				else
					newi += 1
				end

			else
				if negchk then
					animpos=true
					if (not poschk) newi+=1
				else
					newi -=1
				end
			end
			animi=newi
		end
		gsp()
		
		if (e.act) draw_entity(e,animi)
		
		if (e.prev_tab ~= e.sprtab) animi=1 animpos=true 

	end,1,true)
	return rig
end


function hor_wave_print(_str,_x,_y,_col,_dst, _i,_spd)
	local dst = _dst or 4
	local spd = _spd or 1
	local i = _i or t()
	local x = _x
	local xm = 1
	for c=1,#_str do
		local s=sub(_str,c,c)
		local y = _y+cos((i+c/#_str*2)/spd)*dst
		print(s,x-1+(4*xm),y+1,1)
		print(s,x+(4*xm),y,_col)
		xm+=1
	end
end

-->8
-- coroutine functions
function create_timer(_callback, _max, _loop, _lc, _finally, _call_asap)
	local loop = _loop or false 
	local lc = _lc
    local finally = _finally
    local call_asap = _call_asap or false
    local call_index = 1
	local max = _max or 1
    if call_asap then
        call_index = 1
    else
        call_index = max
    end
    local new_timer = cocreate(function()
		local i=1
		local li=1
        while i<=max do
            yield()
            if (i==call_index) _callback()
			if (i==max) then
				if (loop) then
					if (lc~=nil and li>=lc) then
                        break 
                    end
					i=0
					li+=1
				end
			end
			i+=1
        end
        if (finally~=nil) finally() -- printh('running _finally in timer') 
    end)
        -- add(routines, new_timer)
    return new_timer
end

function manage_routines(_t)
    local t = _t or routines
    for i, routine in pairs(t) do
        manage_routine(routine)
    end
end

function manage_routine(routine)
	if routine~=nil then
		if costatus(routine) then
			a,e = coresume(routine)
            if (e) printh('COROUTINE EXCEPTION: '..e)
		end
		if costatus(routine)=='dead' then
            del(aroutines, routine)
			del(routines, routine)
			del(drigs, routine)
		end
	end
end

function yields(n) for i=1,n do yield() end end

-->8
-- entity functions
function clean_ent(e)
	del(routines,e.behavior)
	del(aroutines,e.behavior)
	del(routines,e.pathing)
	del(aroutines,e.pathing)
	del(drigs, e.draw_rig)
	del(entities, e)
end

function create_ent(_sprtab, _pid, _pos, _mot, _coll_box, _pal)
	local e={
		shtdelay=10,
		pid=_pid or 2,
		sprtab=_sprtab or {240},
		prev_tab = {}, -- previous animation table, stored to track animation index when it swaps
		animdelay = 5,
		animwobble = false,
		sprflip = false,
		pal=_pal or {},
		act=true,
		pos = _pos or {
			x=36, --x
			y=36, --y,
			w=7,
			h=7
		},
		mot = _mot or {
			dx=0, --dx
			dy=0, --dy,
			a=0.075,
			mspd=0.7,
			drg=0.9,
			ang=0
		},
		coll_box = _coll_box or create_coll_box(0, 6, 7, 4, function()  end)
	}
	e.mot.oa=e.mot.a
	e.draw_rig = ent_drawing_rig(e)
	add(aroutines, e.shadow)
	add(drigs, e.draw_rig)
	add(entities, e)
	return e
end



function draw_entity(e,i)
	local ds = function()
		-- printh('draw print index: '..i)
		
		if e.act then
			local x,y,w,h = e.pos.x,e.pos.y,e.pos.w,e.pos.h
			ovalfill(x,y+h,x+w,y+h+2,0)
			spr(e.sprtab[i],e.pos.x, e.pos.y,1,1, e.sprflip)
			e.prev_tab = e.sprtab
		end
	end

	if e.animdelay > 1 then
		for d=0, e.animdelay do
			ds()
			yield()
			if (e.sprtab ~= e.prev_tab) i=1 --printh('sprtab~=prev_tab')
			ds()
		end
	else
		ds()
	end
end

function move_entity(p)
	p.context_show=false
	

	--if we acceleration keeps
	--getting added, they will just
	--speed up forever. so we need
	--to limit the speed to a max
	--speed in both horizontal and
	--vertical directions.
	p.mot.dx=mid(-p.mot.mspd,p.mot.dx,p.mot.mspd)
	p.mot.dy=mid(-p.mot.mspd,p.mot.dy,p.mot.mspd)

	--before doing any movement,
	--just check if they are next
	--to a wall, and if so, don't
	--let allow movement in that
	--direction.
	wall_check(p)

	--before the player is moved,
	--movement needs to be checked
	--to see if the player actually
	--can move in that direction.
	if (can_move(p,p.mot.dx,p.mot.dy)) then
		--actually move the player to
		--the new location
		p.pos.x+=p.mot.dx
		p.pos.y+=p.mot.dy
	
	--but if the player cannot move
	--into that spot, find out how
	--close they can get and move
	--them there instead.
	else
		
		--create temporary variables
		--to store how far the player
		--is trying to move.
		tdx=p.mot.dx
		tdy=p.mot.dy
		
		--now we're going to make
		--tdx,tdy shorter and shorter
		--until we find a new position
		--that the player can move to.
		while (not can_move(p,tdx,tdy)) do
			printh(p.pid..': cant move')
			--if the amount of x movement
			--has been shortened so much
			--that it's practically 0,
			--just set it to 0.
			if (abs(tdx)<=0.1) then
				tdx=0
			
			--but if it's not too small,
			--make it 90% of what it was
			--before. (this shortens the
			--amount the player is trying
			--to move in that direction.)
			else
				tdx*=0.9
			end
			
			--do the same thing for y
			--movement.
			if (abs(tdy)<=0.1) then
				tdy=0
			else
				tdy*=0.9
			end
			if tdx==0 and tdy==0 then
				tdx=p.mot.dx*-1/10*0.9
				tdy=p.mot.dy*-1/10*0.9
				break

			end
		end

		--now that we've shorted the
		--distance the player is
		--trying to move to something
		--actually possible, actually
		--move the player to that new
		--shortened distance.
		p.pos.x+=tdx
		p.pos.y+=tdy
	end 
	
	--if the player's still moving,
	--then slow them down just a
	--bit using the drag amount.
	if (abs(p.mot.dx)>0) p.mot.dx*=p.mot.drg
	if (abs(p.mot.dy)>0) p.mot.dy*=p.mot.drg
	
	--if they are going slow enough
	--in a particular direction,
	--just bring them to a halt.
	if (abs(p.mot.dx)<0.01) p.mot.dx=0
	if (abs(p.mot.dy)<0.01) p.mot.dy=0

	pi=3.14
end


-->8
-- mapper functions

-->8
-- stage1 functions

function init_stage1()
	music(0)
	for i=1, max_ents do
		create_sml_goomba(randbi(16,100), randbi(16,100))
	end
	init_players()
	players[2].act=false
end

function draw_stage1()
	map(0,0,0,0,32,32)	
end

function update_stage1()
	if not scene_switch then
		for i, p in pairs(players) do
			update_coll_box(p)
			if p.act then 
				update_controls(p)
				if (not cament.moving) move_entity(p) 
			end
		end
		update_camera()
	end
end


-->8
-- camera code
	
function move_camera(newx,_newy)
	newy = _newy or cament.pos.y
	local dx,dy = 0,0
	cament.moving = true
	local tdst=2
	local a = aget(newx,newy,cament.pos.x,cament.pos.y)
	dx-=cos(a)
	dy-=sin(a)
	local newr = create_timer(function()
		while tdst>1 do
			tdst = dst_basic(newx,newy,cament.pos.x,cament.pos.y)
			cament.pos.x+=dx*(tdst/6)
			cament.pos.y+=dy*(tdst/6)
			players[1].pos.x+=dx*0.3
			players[1].pos.y+=dy*0.3
			yield()
		end
		cament.pos.x = newx
		cament.pos.y = newy
		cament.moving=false
	end,1) 
	add(routines, newr)
end

function update_camera()
	local p1p,cpos = players[1].pos,cament.pos
	local x,y,w,h = p1p.x,p1p.y,p1p.w,p1p.h
	if not cament.moving then
		if x < cpos.x then
			move_camera(cpos.x-128)
		elseif x+w > cpos.x+127 then
			move_camera(cpos.x+128)
		end

		if y < cpos.y then
			move_camera(cpos.x,cpos.y-128)
		elseif y+h > cpos.y+127 then
			move_camera(cpos.x,cpos.y+128)
		end
	end
	camera(cpos.x,cpos.y)
end

-->8
-- math functions

--random int between 0,h
function rand(h) --exclusive
    return flr(rnd(h))
end
function randi(h) --inclusive
    return flr(rnd(h+1))
end

--random int between l,h
function randb(l,h) --exclusive
    return flr(rnd(h-l))+l
end
function randbi(l,h) --inclusive
    return flr(rnd(h+1-l))+l
end

function aget(x1,y1,x2,y2) return atan2(-(x1-x2), -(y1-y2)) end

function oaget(o1,o2)
	return aget(o1.pos.x, o1.pos.y, o2.pos.x, o2.pos.y)
end

function dst(o1,o2)
	local x0,y0=o1.pos.x,o1.pos.y
	local x1,y1=o2.pos.x,o2.pos.y
  	return dst_basic(x0,y0,x1,y1)
end
function dst_basic(x0,y0,x1,y1)
  -- scale inputs down by 6 bits
  local dx=(x0-x1)/64
  local dy=(y0-y1)/64
  
  -- get distance squared
  local dsq=dx*dx+dy*dy
  
  -- in case of overflow/wrap
  if(dsq<0) return 32767.99999
  
  -- scale output back up by 6 bits
  return sqrt(dsq)*64
end
function sqr(x) return x*x end

-->8
--collision functions

--this function takes an object
--and a speed in the x and y
--directions. it uses those
--to check the four corners of
--the object to see it can move
--into that spot. (a map tile
--marked as solid would prevent
--movement into that spot.)

function create_coll_box(_cx, _cy, _cw, _ch, _coll_callback)
    local coll_box = {
        cx = _cx,
        cy = _cy,
        cw = _cw,
        ch = _ch,
        cx_l = 0,
        cx_r = 0,
        cy_t = 0,
        cy_b = 0,
		coll_callback = _coll_callback or function() end
    }
	return coll_box
end

function check_pos_collision(x,y, coll_box)
	return (coll_box.cx_r>=x and
	coll_box.cx_l<=x) and
	(coll_box.cy_b>=y and
	coll_box.cy_t<=y)
end

function simple_coll_check(cb1, cb2)
	local touching = (cb1.cx_r>=cb2.cx_l and
	cb1.cx_l<=cb2.cx_r) and
	(cb1.cy_b>=cb2.cy_t and
	cb1.cy_t<=cb2.cy_b)
	-- printh('simple_coll_check: '..tostr(touching))
	return touching
end

function check_collision(e)
	-- this function specifically checks the collision between existing entities in the world
    
    collide = false
    if e.pid<2 then
		for i, tar in pairs(entities) do
			if tar.act==true and e.act==true and tar.pid~=e.pid then
				if tar.coll_box~=nil then
					if simple_coll_check(e.coll_box, tar.coll_box) then
							e.coll_box:coll_callback(tar)
							-- printh(tar.pid)
					end
				end
			end
		end
	end
    return collide
end

function draw_coll_box(coll_box)
    -- top
    line(coll_box.cx_l,coll_box.cy_t,coll_box.cx_r,coll_box.cy_t,3)
    --bottom
    line(coll_box.cx_l,coll_box.cy_b,coll_box.cx_r,coll_box.cy_b,14)

    --left
    line(coll_box.cx_l,coll_box.cy_t,coll_box.cx_l,coll_box.cy_b,12)

    --right
    line(coll_box.cx_r,coll_box.cy_t,coll_box.cx_r,coll_box.cy_b,2)

end

function update_coll_box(e)
    e.coll_box.cx_l = e.pos.x + e.coll_box.cx
    e.coll_box.cx_r = e.pos.x + e.coll_box.cx + e.coll_box.cw
    e.coll_box.cy_t = e.pos.y + e.coll_box.cy
    e.coll_box.cy_b = e.pos.y + e.coll_box.cy + e.coll_box.ch
end

function can_move(a,dx,dy)
	
	--create variables for the
	--left, right, top, and bottom
	--coordinates of where the
	--object is trying to be.
	local nx_l=a.pos.x+dx       --lft
	local nx_r=a.pos.x+dx+a.pos.w   --rgt
	local ny_t=a.pos.y+dy       --top
	local ny_b=a.pos.y+dy+a.pos.h   --btm

	--now check each corner of
	--where the object is trying to
	--be and see if that spot is
	--solid or not.
	local top_left_solid=solid(nx_l,ny_t)
	local btm_left_solid=solid(nx_l,ny_b)
	local top_right_solid=solid(nx_r,ny_t)
	local btm_right_solid=solid(nx_r,ny_b)

	--if all of those locations are
	--not solid, the object can
	return not (top_left_solid or
			btm_left_solid or
			top_right_solid or
			btm_right_solid)
end

function off_cam(x,y)
	if cament.pos.x>x or cament.pos.x+127<x or cament.pos.y>y or cament.pos.y+127<y then
		return true
	end
	return false
end
--checks an x,y pixel coordinate
--against the map to see if it 
--can be walked on or not
function solid(x,y)

 --pixel coords -> map coords
 local map_x=flr(x/8)
 local map_y=flr(y/8)
 
 --what sprite is at that spot?
 local map_sprite=mget(map_x,map_y)
 
 --what flag does it have?
 local flag=fget(map_sprite)

 --if the flag is 1, it's solid
 return flag==1
end

--this checks to see if the
--player is next to a wall. if
--so, don't let them try to move
--in that direction.
function wall_check(a)
 
 --going left?
 if (a.mot.dx<0) then
  --check both left corners for
  --a wall.
  local wall_top_left=solid(a.pos.x-1,a.pos.y)
  local wall_btm_left=solid(a.pos.x-1,a.pos.y+a.pos.h)

  --if there is a wall in that
  --direction, set x movement
  --to 0.
  if (wall_top_left or wall_btm_left) then
   a.mot.dx=0
  end
  
 --going right?
 elseif (a.mot.dx>0) then
  --check both right corners for
  --a wall.
  local wall_top_right=solid(a.pos.x+a.pos.w+1,a.pos.y)
  local wall_btm_right=solid(a.pos.x+a.pos.w+1,a.pos.y+a.pos.h)

  --if there is a wall in that
  --direction, set x movement
  --to 0.
  if (wall_top_right or wall_btm_right) then
   a.mot.dx=0
  end
 end

 --going up?
 if (a.mot.dy<0) then
  --check both top corners for
  --a wall.
  local wall_top_left=solid(a.pos.x,a.pos.y-1)
  local wall_top_right=solid(a.pos.x+a.pos.w,a.pos.y-1)

  --if there is a wall in that
  --direction, set y movement
  --to 0.
  if (wall_top_left or wall_top_right) then
   a.mot.dy=0
  end
  
 --going down?
 elseif (a.mot.dy>0) then
  --check both bottom corners 
  --for a wall.
  local wall_btm_left=solid(a.pos.x,a.pos.y+a.pos.h+1)
  local wall_btm_right=solid(a.pos.x+a.pos.w,a.pos.y+a.pos.h+1)

  --if there is a wall in that
  --direction, set y movement
  --to 0.
  if (wall_btm_right or wall_btm_left) then
   a.mot.dy=0
  end
 end

 --the two commented lines of 
 --code below do the same thing
 --as all the lines of code 
 --above, but are just condensed
	
	--if ((a.mot.dx<0 and (solid(a.pos.x-1,a.pos.y) or solid(a.pos.x-1,a.pos.y+a.pos.h-1))) or (a.mot.dx>0 and (solid(a.pos.x+a.pos.w,a.pos.y) or solid(a.pos.x+a.pos.w,a.pos.y+a.pos.h-1)))) p.mot.dx=0
	--if ((a.mot.dy<0 and (solid(a.pos.x,a.pos.y-1) or solid(a.pos.x+a.pos.h-1,a.pos.y-1))) or (a.mot.dy>0 and (solid(a.pos.x,a.pos.y+a.pos.h) or solid(a.pos.x+a.pos.w-1,a.pos.y+a.pos.h)))) p.mot.dy=0
end
__gfx__
00000000000000000000000000000000000000000044444000444440004444400000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000004444400441ff140441ff14044fff4400000440000711000044f0000044444001111100000000000000000000000000
00000000000000000000000000000000044fff4404ffeef404ffeef404f1ff140000ff440071190004419f70044fff44117cc710000000000000000000000000
0000000000000000000000000000000004f1ff1400fffff000fffff000ffee9f0199f1f400f9990004ffe91704fffff41c7cc710044444000044444000444440
0000000000000000000000000000000000ffeef00f9999000f9999f0000999f00119eff40f9eeff004ffe91100f1ff100cc11c0044fff440044fff44044fff44
000000000000000000000000000000000f9999000f11110000111100000911700719eff4041ff1f404f1f99100999900177771004f1ff14004f1ff1404fffff4
00000000000000000000000000000000001111f0077000000700700000011700007f9144044fff44044ff0000f1111f0011110000fffff0f70fffff000f1ff10
00000000000000000000000000000000070070000000000000000000000000000000f44000444440004400000700007000700700711999f00711999f711999ff
00000000000000000000000000444440004444400000000000000000000000000000000000dddd00000000000044440000444400000000000000000000000000
000000000000000000444440044fff44044fff44004444400444440004444400044444000d7667d0004444000444444004444440004444000044440000444440
0000000000000000044fff4404f1ff1404f1ff14044fff4444fff44044fff44044fff4400d7667d004444440044444f0044444f00444444004444440044fff44
000000000000000004f1ff1400fffff000fffff004f1ff144fbffb404fbffb404fbffb4000622600044444f00044ffdd0044ffdd044444f0044444f004f1ff14
000000000000000000fffff0009999000099990000fffff00ffeef000ffeef000ffeef00669999660044ffdd009999f0009999f00044ffdd0044ffdd00fffff0
00000000000000000099990000111170071111000099990009999ff009999ff009999ff000111100009999f00011117007111100009999f0009999f000999900
0000000000000000001111700700000000000070071111000111170071111000711110000011110000111170070000000000007007111100001111000f1111f0
00000000000000000070000000000000000000000000070007000000000007000000700007700770007000000000000000000000000007000070070000700700
08828200000000800022200000288200000000000000000000000000000000000000000000000000000000000044440000444400000000000000000000000000
89289820002802980289820002899820000000000000000000000000000000000000000000000000004444000444444004444440004444000044440000000000
0208998202898028289a98202899a98200000000000000000000000000000000000000000000000004444440044444f0044444f0044444400444444000000000
0089a998889a988289a7a980899a7a92000000000000000000000000000000000000000000000000044444f00044ff000044ff00044444f0044444f000000000
089a7a9889a7a998899a98002889a9820000000000000000000000000000000000000000000000000044ff0000999900009999000044ff000044ff0000000000
0289a982889a99822899802082089820000000000000000000000000000000000000000000000000009999000011117007111100009999000099990000000000
00289820028998200289829889208200000000000000000000000000000000000000000000000000001111700700000000000070071111000f1111f000000000
00088800002882000028288008000000000000000000000000000000000000000000000000000000007000000000000000000000000007000070070000000000
0cc1c100000000c000111000001cc1000f4444f04f4444f000444400000000000000000000000000000000000044444000444440000000000000000000000000
cc1ccc10001c01cc01ccc10001cccc104f4ff4f04f4ff4f0041ff14000000000000000000000000000444440044fff44044fff44004444400044444000000000
010cccc101ccc01c1cc7cc101ccc7cc1491ff190091ff19004feef40000000000000000000000000044fff4404f1ff1404f1ff14044fff44044fff4400000000
00cc7cccccc7ccc1cc777cc0ccc777c109feef9009feef90f0ffff0f00000000007000700000000004f1ff1400ffeddd00ffeddd04f1ff1404f1ff1400000000
0cc777cccc777cccccc7cc001ccc7cc100999900009999000f9999f000000000007000700000000000ffeddd0099fdf00099fdf000ffeddd00ffeddd00000000
01cc7cc1ccc7ccc11cccc010c10ccc100011110000111100001111000000000007670767000000000099fdf000111170071111000099fdf00099fdf000000000
001ccc1001cccc1001ccc1cccc10c1000011110000111100001111000000000006d606d600000000001111700700000000000070071111000011110000000000
000ccc00001cc100001c1cc00c000000007707700077077007700770000000000d5d0d5d00000000007000000000000000000000000007000070070000000000
06000000000000000000000000011170000111700001117001444000000000000004441000000000000000004224422442244224b3bb333333b3333311111111
dd6111700661117000011170011cc720011cc720011cc7204414441001444410014441440000000000000000422222444222224433bb33333333333316616661
0dd6c720ddd6c720011cc7201cccc7201cccc7201cccc7204764414444144144441446740000000000000000224224442242244433333b333b3b33b316516d51
ddd6c7201dd6c720166cc720ddd6cc101cc6cc101dd6cc1043744674476446744764473400000000000000002444244424442444333333333333333316516551
1dd6cc101cc6cc10ddd6cc10166ccc111dd6cc11ddd6cc1143788734437447344378873400000000000000002444244424442444333b33333333b33311111111
1ccccc111ccccc111ccccc1149999400ddd694004dd69400444887344378873443788444000000000000000022442442224424423b3333b33333333316666651
4999940049999400499994000444400006644000dd64400011fff44444488444444fff1100000000000000004222222222222222333333333b33333316dddd51
04444000044440000444400000000000000000000600000000000f1111ffff1111f00000000000000000000044244222242442243333b33333b33b3b16555551
00114444400000000000000000000000000000044444110002027702207720200005555005516500000000004224422222244224333333333333333311111111
01111444444411000011444444441100001144444441111000771b7007b17700005165007dd17550000000004222224222222244b3333b3333333b3316616651
044111444441111001111444444111100111144444111440271771722717717205d1750507ddd505000000002242244222422444333333333b33333316516d51
44441114441114400441114444111440044111444111444407b1778008771b705ddddd5d0000dd5d000000002444244224442444333b33333333333b16516551
4466d11441114444444411144111444444441114411d6644187788822888778149999ddd00009ddd00000000244424442444244433333333333b333311111111
46776d14411d66444466d114411d66444466d11441d677641888871001788881049994050799940500000000224424422244244233333b333333333316666651
4733764441d6776446776d1441d6776446776d14446733740178110221118710004444007999944000000000422222224222222233b33333333333b316dddd51
473376444467337447337644446733744733764444673374201102000020110200044440044444000000000044244224442442243333333b33b3333316555551
47337648846733744733764444673374473376488467337400111100000000001111111111111111555555551111111111111111111111111111111111111111
473376888867337447337648846733744733768888673374011333100001110018fff8f116fff6f1555555551661666666616666666166611661666116616651
4477648888673374473376888867337447337688884677440137b7100011331017899781176997615555555516516ddddd516ddddd516d5116516d5116516d51
0444442288467744447764888846774444776488224444400131b1100117b7101789978117699761555555551651655555516555555165511651655116516551
01111fff22444440044444222244444004444422fff1111011bbb3100131b1101f9999911f999991555555551111111111111111111111111111111111111111
1dd51ffffff1111001111ffffff1111001111ffffff15dd113bb131011bbb3101f9888811f966661555555551666666166666661666666511666665116666651
11111000fff15dd11dd51ffffff15dd11dd51fff0001111113bb131013bb13101f8888811f666661555555551655555165555551655555511655555116555551
00000000000111111111100000011111111110000000000013bbb31013bb13111111111111111111555555551111111111111111111111111111111111111111
000570000000000000000000000d5000111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000
00076000000760000006d0000005700012ffff211f2fff2112fff2f118ffff8116ffff611f8fff811f6fff610000000000000000000000000000000000000000
0076d5000006d000000d500000576d00172992711279927117299721178998711769967118799871167996710000000000000000000000000000000000000000
076d5760006d570000d576000576d570172992711279927117299721178998711769967118799871167996710000000000000000000000000000000000000000
76d576d506d576d50d576d50576d576d1f9999911f9999911f9999911f9999911f9999911f9999911f9999910000000000000000000000000000000000000000
555555556d576d57d576d576555555551f9229911f9229911f9229911f8888911f66669118888991166669910000000000000000000000000000000000000000
011001005555555555555555001001101f2992911f2992911f2992911f8888911f66669118888891166666910000000000000000000000000000000000000000
11100110011001101100001101100111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000010000010000000000000001010101010100000000010101000000000000000000
0000000000000000000000000000000100000000000000000000000000000001000001000000000000000101010101010000000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6f6f6f6f6f6f4d4d6f6f6f6f6f6f6f6f6f6f6f6f6f6f4d4d6f6f6f6f6f6f6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6f6f6f6f6f6f4d4d6f6f6f6f6f6f6f6f6f6f6f6f6f6f4c4c6f6f6f6f6f6f6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f4d4d4d4d4d4d4d4d4d4d4d4d4d4d6f6f4c4c4c4c4c4c4c4c4c4c4c4c4c4c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000a63000630006300061000610006100061000610016100063000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000100201102013020150201602016020150201401011010100001800016000160001700019000000001a000000001a0001b0001b0000000000000000000000000000000000000000000000000000000000
0001000025020280202a0202d02017020180001c0001f00022000240002600026000230001c000170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
