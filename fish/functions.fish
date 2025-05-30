# thx to https://github.com/mduvall/config/

function subl --description 'Open Sublime Text'
  if test -d "/Applications/Sublime Text.app"
    "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" $argv
  else if test -d "/Applications/Sublime Text 2.app"
    "/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl" $argv
  else if test -x "/opt/sublime_text/sublime_text"
    "/opt/sublime_text/sublime_text" $argv
  else if test -x "/opt/sublime_text_3/sublime_text"
    "/opt/sublime_text_3/sublime_text" $argv
  else
    echo "No Sublime Text installation found"
  end
end


function killf
  if ps -ef | sed 1d | fzf -m | awk '{print $2}' > $TMPDIR/fzf.result
    kill -9 (cat $TMPDIR/fzf.result)
  end
end

function clone --description "clone something, cd into it. install it."
    git clone --depth=1 $argv[1]
    cd (basename $argv[1] | sed 's/.git$//')
    yarn install
end

function notif --description "make a macos notification that the prev command is done running"
  #  osascript -e 'display notification "hello world!" with title "Greeting" sound name "Submarine"'
  osascript \
    -e "on run(argv)" \
    -e "return display notification item 1 of argv with title \"command done\" sound name \"Submarine\"" \
    -e "end" \
    -- "$history[1]"
end

function all_binaries_in_path --description "list all binaries available in \$PATH, even if theres conflicts"
  # based on https://unix.stackexchange.com/a/120790/110766 but tweaked to work on mac. and then made it faster.
  find -L $PATH -maxdepth 1 -perm +111 -type f
  #gfind -L $PATH -maxdepth 1 -executable -type f # shrug. probably can delete this.
end

function stab --description "stabalize a video"
  set -l vid $argv[1]
  ffmpeg -i "$vid" -vf vidstabdetect=stepsize=32:result="$vid.trf" -f null -; 
  ffmpeg -i "$vid" -b:v 5700K -vf vidstabtransform=interpol=bicubic:input="$vid.trf" "$vid.mkv";  # :optzoom=2 seems nice in theory but i dont love it. kinda want a combo of 1 and 2. (dont zoom in past the static zoom level, but adaptively zoom out to full when possible)
  ffmpeg -i "$vid" -i "$vid.mkv" -b:v 3000K -filter_complex hstack "$vid.stack.mkv"
  # vid=Dalton1990/Paultakingusaroundthehouseagai ffmpeg -i "$vid.mp4" -i "$vid.mkv" -b:v 3000K -filter_complex hstack $HOME/Movies/"Paultakingusaroundthehouseagai.stack.mkv"
  command rm $vid.trf
end


function md --wraps mkdir -d "Create a directory and cd into it"
  command mkdir -p $argv
  if test $status = 0
    switch $argv[(count $argv)]
      case '-*'
      case '*'
        cd $argv[(count $argv)]
        return
    end
  end
end

function gz --d "Get the gzipped size"
  printf "%-20s %12s\n"  "compression method"  "bytes"
  printf "%-20s %'12.0f\n"  "original"         (cat "$argv[1]" | wc -c)
  
  # -5 is what GH pages uses, dunno about others
  # fwiw --no-name is equivalent to catting into gzip
  printf "%-20s %'12.0f\n"  "gzipped (-5)"     (cat "$argv[1]" | gzip -5 -c | wc -c)
  printf "%-20s %'12.0f\n"  "gzipped (--best)" (cat "$argv[1]" | gzip --best -c | wc -c)
  
  # brew install brotli to get these as well
  if hash brotli
  # googlenews uses about -5, walmart serves --best 
  printf "%-20s %'12.0f\n"  "brotli (-q 5)"    (cat "$argv[1]" | brotli -c --quality=5 | wc -c)
  printf "%-20s %'12.0f\n"  "brotli (--best)"  (cat "$argv[1]" | brotli -c --best | wc -c)
  end
end

function sudo!!
    eval sudo $history[1]
end


# `shellswitch [bash|zsh|fish]`
function shellswitch
	chsh -s (brew --prefix)/bin/$argv
end

function upgradeyarn
  curl -o- -L https://yarnpkg.com/install.sh | bash
end

function fuck -d 'Correct your previous console command'
    set -l exit_code $status
    set -l eval_script (mktemp 2>/dev/null ; or mktemp -t 'thefuck')
    set -l fucked_up_commandd $history[1]
    thefuck $fucked_up_commandd > $eval_script
    . $eval_script
    rm $eval_script
    if test $exit_code -ne 0
        history --delete $fucked_up_commandd
    end
end

# requires my excellent `npm install -g statikk`
function server -d 'Start a HTTP server in the current dir, optionally specifying the port'    
    # arg can either be port number or extra args to statikk
    if test $argv[1]
      if string match -qr '^-?[0-9]+(\.?[0-9]*)?$' -- "$argv[1]"
        echo $argv[1] is a number
        set port $argv[1]
        statikk --open --port "$port"
      else
        echo "not a number"
        statikk --open $argv[1]
      end
        
    else
        statikk --open
    end
end


function emptytrash -d 'Empty the Trash on all mounted volumes and the main HDD. then clear the useless sleepimage'
    sudo rm -rfv "/Volumes/*/.Trashes"
    grm -rf "~/.Trash/*"
    rm -rfv "/Users/paulirish/Library/Application Support/stremio/Cache"
    rm -rfv "/Users/paulirish/Library/Application Support/stremio/stremio-cache"
    rm -rfv "~/Library/Application Support/Spotify/PersistentCache/Update/*.tbz"
    rm -rfv ~/Library/Caches/com.spotify.client/Data
    rm -rfv ~/Library/Caches/Firefox/Profiles/98ne80k7.dev-edition-default/cache2
end

function conda -d 'lazy initialize conda'
  functions --erase conda
  eval /opt/miniconda3/bin/conda "shell.fish" "hook" | source
  # There's some opportunity to use `psub` but I don't really understand it.
  conda $argv
end

# NVM doesnt support fish and its stupid to try to make it work there.
