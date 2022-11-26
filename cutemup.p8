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
	max_ents=0
	aroutines={}
	routines={}
	entities={}
	cament = create_ent({}, -1, {x=0,y=0,w=4,h=4}, _mot, _coll_box)
	cament.coll_box = cmpnt_new_coll_box(64, 64, 10, 10, function() end)
	del(aroutines, cament.draw_rig)
	del(entities, cament)
	map_cenx,map_ceny=120,120
	s_w=128
	init_players()
	ents=2
	add(routines, test)
	switch_scene(scenes.stage1, true)
end

function _update60()
	if (current_scene~=nil and current_scene.update~=nil) current_scene:update()
	manage_routines()
	for i, p in pairs(players) do
		sys_ent__update_coll(p)
		-- sys_ent__coll_check(p)
	end
end

function _draw()
    cls()
	if (current_scene~=nil and current_scene.draw~=nil) current_scene:draw()
	manage_routines(aroutines)

	print('debug', cament.pos.x,cament.pos.y,8)
	print(#aroutines)
	-- print(#players..' players: ')
	print(players[1].mot.dx..","..players[1].mot.dy)
	
end

-->8
-- player functions

function init_players()
	players={}
	prun = {210,211,212,213}
	pstand = {207}
	for i=0,1 do
		local p = create_ent(prun, i)
		p.coll_box = cmpnt_new_coll_box(2, 2, 4, 4, player_collide)
		p.logic = create_timer(function()
			if p.mot.dx<-0.1 or p.mot.dy < -0.1 or p.mot.dx > 0.1 or p.mot.dy > 0.1 then
				p.sprtab = prun
			else
				p.sprtab = pstand
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

function update_controls(p)
	if (btn(4, p.pid)) printh('z button pressed')
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

function create_testent(_x,_y)
	local p = create_ent({207}, ents, {
		x=_x, --x
		y=_y, --y,
		w=7,
		h=7
	}, {
		dx=0, --dx
		dy=0, --dy,
		-- a=0.2,
		a=randbi(0.3,0.4),
		mspd=0.4,
		drg=0.9,
		ang=0
	}, cmpnt_new_coll_box(0, 0, 6, 4))
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
		sys_ent__update_coll(p)
		sys_ent__coll_check(p)
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
	add(entities, p)
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
		circfill(tx,ty,1,col)
		yield() -- yield processing back to main loop
		for i, ent in pairs(entities) do -- loop through entities to see if any are colliding with path pixel
			if e.pid ~= ent.pid and ent.pid>1 then -- If the entity is another enemy, then continue
				if sys_pos__coll_check(tx,ty, ent.coll_box) then -- if colliding with another enemy
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
	local tdst = dst(ent, ent.targ)
	ent.mot.dx-=cos(ent.mot.ang)--*-(tdst+ent.mot.a)
	ent.mot.dy-=sin(ent.mot.ang)--*-(tdst+ent.mot.a)
	-- ent.mot.dx*=(ent.mot.a)
	-- ent.mot.dy*=(ent.mot.a)
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
				map(32,0,0,0,16,16)
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
		if (cb) cb()
    end)
    add(aroutines, t)
	return t, costatus(t)
end

-->8
-- animation and draw helpers

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
		end
	end
end

function yields(n) for i=1,n do yield() end end

-->8
-- entity functions
function create_ent(_sprtab, _pid, _pos, _mot, _coll_box, _pal)
	local e={
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
			a=0.1,
			mspd=0.5,
			drg=0.9,
			ang=0
		},
		coll_box = _coll_box or cmpnt_new_coll_box(1, 1, 5, 4, function()  end)

	}
	e.mot.oa=e.mot.a
	e.draw_rig = ent_drawing_rig(e)
	add(aroutines, e.draw_rig)
	add(entities, e)
	return e
end


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
		
		if (e.act) draw_entity(e,animi)  sys_ent__draw_coll(e.coll_box)
		
		if (e.prev_tab ~= e.sprtab) animi=1 animpos=true 

	end,1,true)
	return rig
end

function draw_entity(e,i)
	local ds = function()
		spr(e.sprtab[i],e.pos.x, e.pos.y,1,1, e.sprflip)
	end
	if e.mot.dx<-0.01 then
		e.sprflip = true
	elseif e.mot.dx>0.01 then
		e.sprflip=false
	end
	if e.animdelay > 0 then
		for d=1, e.animdelay do
			ds()
			yield()
			if (e.sprtab ~= e.prev_tab) i=1
			ds()
		end
	else
		ds()
	end
end

function move_entity(p)
	p.context_show=false
	
	--when the user tries to move,
	--we only add the acceleration
	--to the current speed.
	if (btn(0,p.pid)) p.mot.dx-=p.mot.a
	if (btn(1,p.pid)) p.mot.dx+=p.mot.a
	if (btn(2,p.pid)) p.mot.dy-=p.mot.a
	if (btn(3,p.pid)) p.mot.dy+=p.mot.a 
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
		create_testent(rnd(128), rnd(128))
	end
	init_players()
	players[2].act=false
end

function draw_stage1()
	map(0,0,0,0,32,32)	
	-- if (cament~=nil) sys_ent__draw_coll(cament.coll_box)
end

function update_stage1()

	for i, p in pairs(players) do
		if (p.act) move_entity(p) update_controls(p)
	end
	update_camera()
end


-->8
-- camera code
	


function update_camera()
	camera(cament.pos.x,cament.pos.y)


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

function cmpnt_new_coll_box(_cx, _cy, _cw, _ch, _coll_callback)
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

function sys_pos__coll_check(x,y, coll_box)
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

function sys_ent__coll_check(e)
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

function sys_ent__draw_coll(coll_box)
    -- top
    line(coll_box.cx_l,coll_box.cy_t,coll_box.cx_r,coll_box.cy_t,3)
    --bottom
    line(coll_box.cx_l,coll_box.cy_b,coll_box.cx_r,coll_box.cy_b,14)

    --left
    line(coll_box.cx_l,coll_box.cy_t,coll_box.cx_l,coll_box.cy_b,12)

    --right
    line(coll_box.cx_r,coll_box.cy_t,coll_box.cx_r,coll_box.cy_b,2)

end

function sys_ent__update_coll(e)
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
	--move into that spot.
	return not (top_left_solid or
			btm_left_solid or
			top_right_solid or
			btm_right_solid)
end

function off_cam(x,y)
	if cament.pos.x>x or cament.pos.x+127<x then
		return true
	elseif cament.pos.y>y or cament.pos.y+127<y then
		return true
	else 
		return false
	end
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
  local wall_btm_right=solid(a.pos.x,a.pos.y+a.pos.h+1)

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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000000000000000000000000000000000000000000dddd0000444440000000000000000000000000004444400000000000000000000000000000000000000000
00444400004444000000000000000000000000000d7667d0044fff4400000440000711000044f000044fff440111110044444000444440004444400800444440
04444440044444400000000000000000000000000d7667d004f1ff140000ff440071190004419f7004fffff4117cc71044ff440044ff440044ff4400044fff44
044444f00f4444400444440000444440004444400062260000ffee9f0199f1f400f9990004ffe91700f1ff101c7cc710f1ff1450f1ff14d8f1ff145004f1ff14
00ffff0000ffff0044fff440044fff44044fff4466999966000999f00119eff40f9eeff004ffe911009999000cc11c00ffeeddd5ffee666dffee666500fffff0
0f999900009999f04f1ff14004f1ff1404fffff400111100000911700719eff4041ff1f404f1f9910f1111f017777100999fdf50999f6fd8999f6f5000999900
00111170071111000fffff0f70fffff000f1ff100011110000011700007f9144044fff44044ff00007000070011110001111000011110000111100000f1111f0
0700000000000070711999f00711999f711999ff07700770000000000000f4400044444000440000000000000070070070070000700700007007000800700700
00444400004444400000000000444440004444400000000000000000000000000000000000000000000000000044444000000000000000000000000000000000
041ff1400441ff1400444440044fff44044fff44004444400044444000444440004444400000000004444400041ff14400444440004444400044444000000000
04feef4004ffeef4044fff4404f1ff1404f1ff14044fff44044fff44044fff44044fff440000000044fff44004feeff4044fff44044fff44044fff4400000000
f0ffff0f00fffff004f1ff1400fffff000fffff004f1ff1404fbffb404fbffb404fbffb40000000041ff1f4000fffff004f1ff1404f1ff1404f1ff1400000000
0f9999f00f9999f000fffff0009999000099990000fffff000ffeef000ffeef000ffeef0000000000feeff000009999f00fffff000fffff000fffff000000000
001111000011110000999900001111700711110000999900009999ff009999ff009999ff00000000009999f00001111f009999f0009f99000f99990000000000
001111000700700000111170070000000000007007111100001111700711110007111100000000000f11110000000077001111f0001111000f11110000000000
07700770000000000070000000000000000000000000070000700000000000700000070000000000000700700000000007007000070007000070700000000000
00000000000000000000000000000000000000000000000000000000000000000f4444f04f4444f0000000000000000000000000000070000000000000000000
04444400044444000000000000444440000000000444440000000000044444004f4ff4f04f4ff4f00000076d0000000000000076000070000000000000000000
44fff44044fff44000000000044fff440000000044fff4400000000044fff440491ff190091ff190000776d5000000000000776d000767000000000000000000
4f1ff1404f1ff1200000000004f1ff14200000004f1ff120000000004f1ff14009feef9009feef900000076d00700070007766d5000767000000000000000000
0ffeef700ffee2277700000000ffeef2277777700ffee227777000000ffeef70009999000099990000000000007000707766dd550076d6700000000000000000
0999996709999926667000000099999f2666666709999926666700000999996700111100001111000000076d07670767007766d50076d6700000000000000000
01111170011112277700000000111112277777700111122777700000011111700011110000111100000776d506d606d60000776d076d5d670000000000000000
070070000700072000000000070000072000000007000720000000000700700000770770007707700000076d0d5d0d5d0000007606d555d60000000000000000
80000002088282000000008000222000002882000cc1c100000000c000111000001cc100000000000d5d0d5d0000000006d555d6000000000000000000000000
0800002089289820002802980289820002899820cc1ccc10001c01cc01ccc10001cccc100000000006d606d6d6700000076d5d67670000000000000000000000
008002000208998202898028289a98202899a982010cccc101ccc01c1cc7cc101ccc7cc100000000076707675d6770000076d670d67700000000000000000000
000820000089a998889a988289a7a980899a7a9200cc7cccccc7ccc1cc777cc0ccc777c10000000000700070d67000000076d6705d6677000000000000000000
00028000089a7a9889a7a998899a98002889a9820cc777cccc777cccccc7cc001ccc7cc10000000000700070000000000007670055dd66770000000000000000
002008000289a982889a9982289980208208982001cc7cc1ccc7ccc11cccc010c10ccc100000000000000000d6700000000767005d6677000000000000000000
0200008000289820028998200289829889208200001ccc1001cccc1001ccc1cccc10c10000000000000000005d67700000007000d67700000000000000000000
2000000800088800002882000028288008000000000ccc00001cc100001c1cc00c0000000000000000000000d670000000007000670000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000101010000000000000001000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000100000000000000000000000000000001000001000000000000000101010101010000000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
aeacacacacacacacacacacacacacacae00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af8d8e8d8e8d8e8d8e8d8e8d8e8d8eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af9d9e9d9e9d9e9d9e9d9e9d9e9d9eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af8d9e9e8e8e8e8d8e8e8e8d8e8d8eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af9e8e8e8e8e9e8e9e9d9e8e8e8e9eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af8d9d8e8e8d8e9e8e8e8e8e8e8e8eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af9d9e9e8e9e9e9e9e9d9e9d9e9d9eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af8d9e9d8e9e9e9e8e8d8e8e8e8d8eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af9d9e9d8e8e8e9d9e9e9e9d9e9d9eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af9e9d9d9e9e9e9e8e9e8e9d8e8d8eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af9d9d9e8e9d8e8e8e9e9e9d8e8e9eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af9d9e9e8e8e9e9e9e8e9d9e9d8e9eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af9e9e8e9e9e9e9e9e9d9e9e9e8e9daf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af9e8e8e9e9e9e8d8e9e8e8d8e8e8eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
af9d8e9e9e9d9e9d9e9d9e8e8e9e9eaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aeafafafafafafafafafafafafafafae00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
