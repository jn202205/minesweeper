require 'byebug'
class Tile

  DELTAS = [[0,1], [0, -1], [1,0], [-1,0], [1,1], [1,-1], [-1,1], [-1,-1]]

  attr_accessor :visual, :board, :neighbors

  def initialize(board, pos)
    @pos = pos
    @visual = "*"
    @bomb = false
    @board = board
    @revealed = []
  end

  def reveal
    # debugger
    get_neighbors(@pos)
    if has_bomb?
      @visual = 'X'
    elsif @neighbors.any?(&:has_bomb?)
      @visual = neigh_bomb_count
    else
      @visual = '_'
      @board.revealed_tiles << self
      no_bombs = @neighbors.select {|neighbor| !neighbor.has_bomb? }
      no_bombs.each do |tile|
        unless @board.revealed_tiles.include?(tile)
          tile.reveal
          @board.revealed_tiles << tile
        end
      end
    end

  end

  # def reveal_helper

    # get_neighbors(@pos)
    # queue = []
    # queue << self
    #
    # until queue.empty?
    #   current = queue.shift
    #   current.reveal
    #   @revealed << current
    #
    #   current.neighbors.each do |neighbor|
    #
    #     unless neighbor.has_bomb? || @revealed.include?(neighbor)
    #       # neighbor.reveal
    #       queue << neighbor
    #     end
    #
    #   end
    #
    # end

  # end

  def neigh_bomb_count
    count = 0
    @neighbors.each do |neighbor|
      count += 1 if neighbor.has_bomb?
    end
    count
  end

  def get_neighbors(pos)
    @neighbors = []
    px, py = pos
    DELTAS.each do |dx, dy|
      new_x, new_y = px+dx, py+dy
      next unless [new_x, new_y].all?{|x| x.between?(0, @board.num_tiles-1)}
      neighbor = @board.tiles[new_x][new_y]
      @neighbors << neighbor if neighbor.is_a?(Tile)
    end

    @neighbors
  end

  def has_bomb?
    @bomb
  end

  def place_bomb
    @bomb = true
  end

end

class Board
  attr_reader :tiles, :board, :num_tiles, :revealed_tiles, :bombs

  def initialize(num_tiles = 9)
    @tiles = Array.new(num_tiles) {Array.new(num_tiles)}
    @num_tiles = num_tiles
    @revealed_tiles = []
    @board
  end

  def make_tiles
    @tiles.each_with_index do |row, x|
      row.each_with_index do |tile, y|
        @tiles[x][y] = Tile.new(self, [x,y])
      end

    end
    true
  end

  def show_board
    @tiles.each do |row|
      row.each do |tile|
        print "#{tile.visual} "
      end
      puts
    end
    true
  end

  def populate_bombs(bombs)
    @bombs = bombs

    until bombs == 0
      row = @tiles.sample
      tile = row.sample

      unless tile.has_bomb?
        tile.place_bomb
        bombs -= 1
      end
    end
  end

end

class Minesweeper
  attr_reader :board
  def initialize(num_tiles = 9)
    @num_tiles = num_tiles
  end

  def generate_board
    @board = Board.new(@num_tiles)
  end

  def run
    generate_board
    @board.make_tiles
    @board.populate_bombs(@num_tiles)

    until over?
      @board.show_board
      get_move
    end

    puts (won? ? "You win!" : "You lose!")
  end

  def over?
    lost? || won?
  end

  def lost?
    over = false
    @board.tiles.each do |row|
      over = row.any? {|tile| tile.visual == 'X'}
      break if over
    end

    over
  end

  def won?
    count = 0
    @board.tiles.each do |row|
      row.each do |tile|
        if tile.visual == '*' || tile.visual == 'F'
          count += 1
        end
      end
    end

    count == @board.bombs
  end

  def get_move
    print 'Enter position:'
    pos = gets.chomp
    flag = pos[0] == 'f' ? true : false

    if flag
      coord = pos[1..-1].strip.split(',')
      place_flag(coord)
    else
      coord = pos.strip.split(',')
      x,y = coord
      @board.tiles[x.to_i][y.to_i].reveal
    end

  end

  def place_flag(coord)
    x,y = coord
    tile = @board.tiles[x.to_i][y.to_i]
    tile.visual = tile.visual == 'F' ? '*' : 'F'
  end

end

Minesweeper.new(9).run
