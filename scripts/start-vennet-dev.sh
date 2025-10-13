#!/bin/bash

SESSION="myproject"

# Check if session exists
tmux has-session -t $SESSION 2>/dev/null

if [ $? != 0 ]; then
  # Create new session detached
  tmux new-session -d -s $SESSION -n editor
  
  # Window 1: Editor
  tmux send-keys -t $SESSION:editor "cd ~/projects/myproject" C-m
  tmux send-keys -t $SESSION:editor "nvim ." C-m
  
  # Window 2: Server
  tmux new-window -t $SESSION:2 -n server
  tmux send-keys -t $SESSION:server "cd ~/projects/myproject" C-m
  tmux send-keys -t $SESSION:server "npm run dev" C-m
  
  # Window 3: Database & Logs (split panes)
  tmux new-window -t $SESSION:3 -n logs
  tmux send-keys -t $SESSION:logs "cd ~/projects/myproject" C-m
  tmux send-keys -t $SESSION:logs "docker-compose up" C-m
  
  # Split pane horizontally for logs
  tmux split-window -h -t $SESSION:logs
  tmux send-keys -t $SESSION:logs "cd ~/projects/myproject" C-m
  tmux send-keys -t $SESSION:logs "tail -f logs/app.log" C-m
  
  # Window 4: Git
  tmux new-window -t $SESSION:4 -n git
  tmux send-keys -t $SESSION:git "cd ~/projects/myproject" C-m
  tmux send-keys -t $SESSION:git "git status" C-m
  
  # Select first window by default
  tmux select-window -t $SESSION:editor
fi

# Attach to session
tmux attach -t $SESSION
