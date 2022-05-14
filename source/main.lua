import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics
local cellSize = nil
local gridXCount = nil
local gridYCount = nil
local speed = nil
local snakeSegments = nil
local directionQueue = nil
local foodPosition = nil

function myGameSetUp()
    cellSize = 20
    gridXCount = playdate.display.getWidth() / cellSize
    gridYCount = playdate.display.getHeight() / cellSize
    speed = 500

    reset()
end

function reset()
    snakeSegments = {
        {x = 3, y = 1},
        {x = 2, y = 1},
        {x = 1, y = 1},
    }
    directionQueue = {'right'}
    moveFood()
    redraw()
end

function moveFood()
    local possibleFoodPositions = {}

    for foodX = 1, gridXCount do
        for foodY = 1, gridYCount do
            local possible = true

            for segmentIndex, segment in ipairs(snakeSegments) do
                if foodX == segment.x and foodY == segment.y then
                    possible = false
                end
            end

            if possible then
                table.insert(possibleFoodPositions, {x = foodX, y = foodY})
            end
        end
    end

    foodPosition = possibleFoodPositions[
        math.random(#possibleFoodPositions)
    ]
end

function redraw()
    -- clear the screen

    gfx.clear()


    -- redraw the food

    gfx.fillCircleInRect(
        ((foodPosition.x - 1) * cellSize) + 5,
        ((foodPosition.y - 1) * cellSize) + 5,
        cellSize - 10,
        cellSize - 10
    )


    -- redraw the snake

    for segmentIndex, segment in ipairs(snakeSegments) do
        -- draw the snake segments

        gfx.fillRect(
            ((segment.x - 1) * cellSize) + 4,
            ((segment.y - 1) * cellSize) + 4,
            cellSize - 8,
            cellSize - 8
        )


        -- draw the snake segment connectors

        local prevSegIndex = segmentIndex - 1
        if prevSegIndex > 0 then
            if snakeSegments[prevSegIndex].x < segment.x then
                gfx.fillRect(
                    (((segment.x - 1) * cellSize) + 4) - 8,
                    ((segment.y - 1) * cellSize) + 4,
                    8,
                    cellSize - 8
                )
            end
            if snakeSegments[prevSegIndex].x > segment.x then
                gfx.fillRect(
                    (((segment.x - 1) * cellSize) + cellSize) - 4,
                    ((segment.y - 1) * cellSize) + 4,
                    8,
                    cellSize - 8
                )
            end
            if snakeSegments[prevSegIndex].y < segment.y then
                gfx.fillRect(
                    ((segment.x - 1) * cellSize) + 4,
                    (((segment.y - 1) * cellSize) + 4) - 8,
                    cellSize - 8,
                    8
                )
            end
            if snakeSegments[prevSegIndex].y > segment.y then
                gfx.fillRect(
                    ((segment.x - 1) * cellSize) + 4,
                    (((segment.y - 1) * cellSize) + cellSize) - 4,
                    cellSize - 8,
                    8
                )
            end
        end
    end

    playdate.timer.performAfterDelay(speed, myTimerClosure)
end

function myTimerClosure()
    if #directionQueue > 1 then
        table.remove(directionQueue, 1)
    end

    -- set the next position based on
    -- the current position and the direction

    local nextXPosition = snakeSegments[1].x
    local nextYPosition = snakeSegments[1].y

    if directionQueue[1] == 'right' then
        nextXPosition = nextXPosition + 1
        if nextXPosition > gridXCount then
            beepAndReset()
            do return end
        end
    elseif directionQueue[1] == 'left' then
        nextXPosition = nextXPosition - 1
        if nextXPosition < 1 then
            beepAndReset()
            do return end
        end
    elseif directionQueue[1] == 'down' then
        nextYPosition = nextYPosition + 1
        if nextYPosition > gridYCount then
            beepAndReset()
            do return end
        end
    elseif directionQueue[1] == 'up' then
        nextYPosition = nextYPosition - 1
        if nextYPosition < 1 then
            beepAndReset()
            do return end
        end
    end


    -- update the snake data

    local canMove = true

    for segmentIndex, segment in ipairs(snakeSegments) do
        if segmentIndex ~= #snakeSegments
        and nextXPosition == segment.x
        and nextYPosition == segment.y then
            canMove = false
        end
    end

    if canMove then
        table.insert(snakeSegments, 1, {
            x = nextXPosition, y = nextYPosition
        })

        if snakeSegments[1].x == foodPosition.x
        and snakeSegments[1].y == foodPosition.y then
            local s = playdate.sound.synth.new(playdate.sound.kWaveSine)
            s:playMIDINote('A4', 0.5, 0.5)
            -- s:playMIDINote('A5', 0.5, 0.5, 0.5)

            moveFood()
        else
            table.remove(snakeSegments)
        end
    else
        beepAndReset()
        do return end
    end

    redraw()
end

function beepAndReset()
    local s = playdate.sound.synth.new(playdate.sound.kWaveSine)
    s:playMIDINote('C5', 0.5, 0.5)
    -- s:playMIDINote('C4', 0.5, 0.5, 0.5)
    reset()
end

myGameSetUp()

function playdate.update()
    if playdate.buttonIsPressed( playdate.kButtonRight )
    and directionQueue[#directionQueue] ~= 'right'
    and directionQueue[#directionQueue] ~= 'left' then
        table.insert(directionQueue, 'right')
    end
    if playdate.buttonIsPressed( playdate.kButtonLeft )
    and directionQueue[#directionQueue] ~= 'left'
    and directionQueue[#directionQueue] ~= 'right' then
        table.insert(directionQueue, 'left')
    end
    if playdate.buttonIsPressed( playdate.kButtonUp )
    and directionQueue[#directionQueue] ~= 'up'
    and directionQueue[#directionQueue] ~= 'down' then
        table.insert(directionQueue, 'up')
    end
    if playdate.buttonIsPressed( playdate.kButtonDown )
    and directionQueue[#directionQueue] ~= 'down'
    and directionQueue[#directionQueue] ~= 'up' then
        table.insert(directionQueue, 'down')
    end

    playdate.timer.updateTimers()
end
