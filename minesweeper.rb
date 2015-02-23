class Tile

  DELTAS = [[0,1], [0, -1], [1,0], [-1,0], [1,1], [1,-1], [-1,1], [-1,-1]]

  attr_accessor :visual, :board

  def initialize(board, pos)
    @pos = pos
    @visual = "*"
    @bomb = false
    @board = board
    @neighbors = get_neighbors(@pos)
  end

  def reveal
    if has_bomb?
      @visual = 'X'
    elsif @neighbors.any?(&:has_bomb?)
      @visual = neigh_bomb_count
    else
      @visual = '_'
    end
  end

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
      next if [new_x, new_y].any?{|x| x.between?(0, @board.num_tiles)}
      neighbor = @board.tiles[new_x][new_y]
      @neighbors << neigbor if neighbor.is_a?(Tile)
    end

    @neighbors
  end

  def has_bomb?
    @bomb
  end

  def place_bomb
    @bomb = true
  end

  def to_s
    "#{self.visual}"
  end


end

class Board
  attr_reader :tiles, :board, :num_tiles
  def initialize(num_tiles = 9)
    @tiles = Array.new(num_tiles) {Array.new(num_tiles)}
    @num_tiles = num_tiles

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
        print tile.visual
      end
      puts
    end
    true
  end

  def populate_bombs
    bombs = 10

    until bombs == 0
      row = @tiles.sample
      tile = row.sample

      unless tile.has_bomb?
        tile.place_bomb
        tile.visual = 'X'
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
    @board.populate_bombs

    until over?
      @board.show_board
      get_move
    end

    puts (won? ? "You win!" : "You lose!")
  end

  def over?
    # lost? or won?
  end

  def lost?
    over = false
    @board.tiles.each do |row|
      over = row.any? {|tile| tile.visual == 'X'}
    end

    over
  end

  def won?
    over = false
    @board.tiles.each do |row|
      over = row.none? {|tile| tile.visual == '*'}
    end

    over
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
