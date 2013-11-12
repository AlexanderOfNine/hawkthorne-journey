local module = {}

function module.find_collision_layer(map)
  for _, layer in ipairs(map.tilelayers) do
    if layer.name == "collision" then
      return layer
    end
  end
  return nil
end

function module.platform_type(tile_id)
  if tile_id >= 21 and tile_id <= 43 then
    return 'oneway'
  else
    return 'block'
  end
end

function module.move_x(map, player, x, y, width, height, dx, dy)
  local collision_layer = module.find_collision_layer(map)
  local direction = player.character.direction
  local new_x = x + dx

  for _, i in ipairs(module.scan_rows(map, x, y, width, height, direction)) do
    local tile = collision_layer.tiles[i]

    if tile then
      local platform_type = module.platform_type(tile.id)

      if direction == "left" then
        local tile_x = math.floor(i % map.width) * map.tileheight

        if platform_type == "block" then

          if new_x <= tile_x then
            return tile_x
          end

        end
      end

      if direction == "right" then
        local tile_x = math.floor((i % map.width) - 1) * map.tilewidth

        if platform_type == "block" then

          -- FIXME: the platform type stuff is super hacky
          if tile_x <= (new_x + width) then
            return tile_x - width
          end

        end
      end
    end
  end

  return new_x
end

function module.move_y(map, player, x, y, width, height, dx, dy)
  local direction = dy <= 0 and 'up' or 'down'
  local new_y = y + dy
  local collision_layer = module.find_collision_layer(map)

  for _, i in ipairs(module.scan_cols(map, x, y, width, height, direction)) do
    local tile = collision_layer.tiles[i]

    if tile then
      local platform_type = module.platform_type(tile.id)

      if direction == "down" then

        if platform_type == "block" then
          local tile_y  = math.floor(i / map.width) * map.tileheight

          if tile_y <= (y + dy + height) then
            -- FIXME: Leaky abstraction
            player.jumping = false
            player:restore_solid_ground()
            return tile_y - height
          end
        end

        if platform_type == "oneway" then
          local tile_y  = math.floor(i / map.width) * map.tileheight
          local player_above_tile = (y + height) <= tile_y 

          if player_above_tile and tile_y <= (y + dy + height) then
            player.jumping = false
            player:restore_solid_ground()
            return tile_y - height
          end
        end
      end

      if diretion == "up" then
        if platform_type == "block" then
          local tile_y  = math.floor(i / map.width + 1) * map.tileheight

          if tile_y >= (y + dy) then
            player.velocity.y = 0
            return tile_y
          end
        end

        if platform_type == "oneway" then
          -- Oneway platforms never collide when going up
        end
      end 
    end
  end
  
  return new_y
end


-- Returns the new position for x and y
function module.move(map, player, x, y, width, height, dx, dy)
  local new_x = module.move_x(map, player, x, y, width, height, dx, dy)
  local new_y = module.move_y(map, player, new_x, y, width, height, dx, dy)
  return new_x, new_y
end

function module.scan_rows(map, x, y, width, height, direction)
  if direction ~= "left" and direction ~= "right" then
    error("Direction must be left or right")
  end

  local rows = {}

  -- Default value for left
  local edge_x = x
  local stop, change = 1, -1

  if direction == "right" then
    stop, change = map.width, 1
  end

  local current_col = math.floor(edge_x / map.tilewidth) + 1
  local top_row = math.floor(y / map.tileheight)
  local bottom_row = math.floor((y + height - 1) / map.tileheight)

  for i=current_col,stop,change do 
    for j=top_row,bottom_row,1 do 
      table.insert(rows, i + (j * map.width))
    end
  end

  return rows
end 

function module.scan_cols(map, x, y, width, height, direction)
  if direction ~= "up" and direction ~= "down" then
    error("Direction must be up or down")
  end

  local cols = {}

  -- Default value for left
  local edge_y = y
  local stop, change = 0, -1

  if direction == "down" then
    stop, change = map.height - 1, 1
  end

  local current_row = math.floor(edge_y / map.tileheight)
  local left_column = math.floor(x / map.tilewidth) + 1
  local right_column = math.floor((x + width - 1) / map.tilewidth) + 1

  for i=current_row,stop,change do 
    for j=left_column,right_column,1 do 
      table.insert(cols, i * map.width + j)
    end
  end

  return cols
end


return module
