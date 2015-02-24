require 'byebug'
require 'yaml'


class Tile
  DELTAS = [[0, 1], [0, -1], [1, 0], [-1, 0],
            [1, 1], [1, -1], [-1, 1], [-1, -1]]

  attr_accessor :visual, :board, :neighbors

  def initialize(board, pos)
    @pos = pos
    @visual = "*"
    @bomb = false
    @board = board
    # @revealed = []
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

  def neigh_bomb_count
    @neighbors.select(&:has_bomb?).count
  end

  def get_neighbors(pos)
    @neighbors = []
    px, py = pos
    DELTAS.each do |dx, dy|
      new_x, new_y = px + dx, py + dy
      next unless [new_x, new_y].all? do |x|
        x.between?(0, @board.num_tiles - 1)
      end
      neighbor = @board.tiles[new_x][new_y]
      @neighbors << neighbor
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

  def initialize(num_tiles)
    @tiles = Array.new(num_tiles) { Array.new(num_tiles) }
    make_tiles
    @num_tiles = num_tiles
    @revealed_tiles = []
    @board
  end

  def make_tiles
    @tiles.each_with_index do |row, x|
      row.each_with_index do |tile, y|
        @tiles[x][y] = Tile.new(self, [x, y])
      end
    end

    nil
  end

  def show_board
    @tiles.each do |row|
      row.each do |tile|
        print "#{tile.visual} "
      end
      puts
    end

    nil
  end

  def display_bombs
    @tiles.each do |row|
      row.each do |tile|
         tile.visual = 'X' if tile.has_bomb?
      end
    end

    show_board
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
    @board = Board.new(@num_tiles)
  end

  def run
    @board.populate_bombs(@num_tiles)
    load_game_option || play
  end

  def play
    until over?
      @board.show_board
      get_move
    end

    @board.display_bombs
    puts (won? ? "You win!" : "You lose!")
  end

  def save_game_option
    File.open('minesweeper.yml', 'w') do |f|
      f.puts self.to_yaml
    end
  end

  def load_game_option
    puts "Do you want to load a game? (y/n)"
    input = gets.chomp
    if input == 'y'
      contents = YAML.load_file('minesweeper.yml')
      contents.play
    end
  end

  def over?
    lost? || won?
  end

  def lost?
    over = false
    @board.tiles.each do |row|
      over = row.any? { |tile| tile.visual == 'X' }
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
    print 'Enter position: (Enter "save"/"quit" to save/quit game)'
    pos = gets.chomp
    if pos == 'save'
      save_game_option
      return
    elsif pos == 'quit'
      Kernel.exit(1)
      return
    end

    if pos[0] == 'f'
      coord = pos[1..-1].strip.split(',').map(&:to_i)
      place_flag(coord)
    else
      coord = pos.strip.split(',').map(&:to_i)
      x, y = coord
      @board.tiles[x][y].reveal
    end

  end

  def place_flag(coord)
    x, y = coord
    tile = @board.tiles[x][y]
    tile.visual = tile.visual == 'F' ? '*' : 'F'
  end

end

if __FILE__ == $PROGRAM_NAME
  Minesweeper.new.run
end
