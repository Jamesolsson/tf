require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

enable :sessions

get('/')do
    slim(:register)
end

before('/protected/*') do
  p "These are protected_methods"
  if session[:id] ==  nil
    #Ingen användare är inloggad
    redirect('/showlogin')
  end
end 


get('/showlogin')do
  slim(:login)
end


post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/gymi.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    pwdigest = result["pwdigest"]
    id = result["id"]
  
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      redirect('/protected/exercises')
    else
      "FEL LÖSENORD"
    end

  rescue NoMethodError => e
    # Handle the case where params[:username] or params[:password] is nil
    session[:error] = "Exercise already added"

    redirect('/showlogin')

end

get('/protected/exercises') do
  db = SQLite3::Database.new("db/gymi.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM exercises ORDER BY muscle_grupp ASC;")

  slim(:"exercises/index", locals: { exercises_result: result })


end
post('/add') do

  user_id = session[:id]
  exercise_id = params[:exercise_id]

  db = SQLite3::Database.new('db/gymi.db')
  db.execute("INSERT INTO users_exercises_rel (user_id, exercises_id) VALUES (?, ?);", user_id, exercise_id)
  redirect('/protected/exercises')


  redirect('/protected/exercises')
end

post('/create') do
  name = params[:name]
  muscle_group = params[:muscle_group]
  user_id = session[:id]

  db = SQLite3::Database.new('db/gymi.db')

  # Insert the exercise into the exercises table
  db.execute("INSERT INTO exercises (name, muscle_grupp) VALUES (?, ?)", name, muscle_group)

  # Get the ID of the last inserted exercise
  exercise_id = db.last_insert_row_id

  # Insert the association into the users_exercises_rel table
  db.execute("INSERT INTO users_exercises_rel (user_id, exercises_id) VALUES (?, ?)", user_id, exercises_id)

  redirect('/user_exercises')
end

post('/remove') do
  exercise_id = params[:exercise_id].to_i
  user_id = session[:id].to_i

  db = SQLite3::Database.new('db/gymi.db')
  db.execute("DELETE FROM users_exercises_rel WHERE user_id = ? AND exercises_id = ?", user_id, exercise_id)
  
  redirect('/user_exercises')
end

get('/user_exercises') do
  user_id = session[:id]
  
  db = SQLite3::Database.new('db/gymi.db')
  db.results_as_hash = true
    
  # Fetch exercises associated with the current user from the join of exercises and users_exercises_rel tables
  @user_exercises = db.execute("SELECT exercises.name, exercises.muscle_grupp, exercises.id 
  FROM exercises 
  INNER JOIN users_exercises_rel ON exercises.id = users_exercises_rel.exercises_id 
  WHERE users_exercises_rel.user_id = ? 
  ORDER BY exercises.muscle_grupp ASC", user_id)
  
  slim(:"exercises/user_exercises", locals: { user_exercises: @user_exercises })
end
post('/users/new')do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/gymi.db')
    db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",username,password_digest)
    redirect('/showlogin')
  else
    "Fel Lösenord"
  end
end

get("/program")do 

  db = SQLite3::Database.new('db/gymi.db')
  db.results_as_hash = true
  program = db.execute("SELECT * FROM program")
  

  slim(:"/program/index", locals:{ program: program })
end

#rout för namn 
post('/program/name')do 
  program_name = params[:program_name]

  db = SQLite3::Database.new('db/gymi.db')
  db.execute("INSERT INTO program (program_name) VALUES (?)", program_name)

  
  # Retrieve the last inserted program_id
  program_id = db.last_insert_row_id

  # Store the program_id in the session
  session[:program_id] = program_id
  
  redirect('/program/new')
end


#route som lägger till weight m.m.---
post('/program/new') do
  exercises_id = params[:exercise_id]
  sets = params[:sets]
  reps = params[:reps]
  weight = params[:weight]
  
  # Retrieve the program_id from the session
  program_id = session[:program_id]

  db = SQLite3::Database.new('db/gymi.db')
  db.results_as_hash = true

  db.execute("INSERT INTO exercise_program_rel (program_id, exercises_id, sets, reps, weight) VALUES (?, ?, ?, ?, ?)",
        program_id, exercises_id, sets, reps, weight)

  redirect('/program/new')
end
get('/program/new') do
  user_id = session[:id]

  db = SQLite3::Database.new('db/gymi.db')
  db.results_as_hash = true
  
  # Fetch exercises that have no user_id or the same user_id as the session ID
  @exercises = db.execute("SELECT id, name FROM exercises WHERE user_id IS NULL OR user_id = ?", user_id)

  slim(:"program/new", locals: { exercises: @exercises })
end


get("/user/index") do 
  db = SQLite3::Database.new('db/gymi.db')
  db.results_as_hash = true
  
  # Fetch programs associated with the current user
  user_id = session[:id]
  programs = db.execute("SELECT program.program_id, program.program_name, exercises.name, exercises.muscle_grupp, exercise_program_rel.sets, exercise_program_rel.reps, exercise_program_rel.weight
  FROM program
  JOIN exercise_program_rel ON program.program_id = exercise_program_rel.program_id
  JOIN exercises ON exercise_program_rel.exercises_id = exercises.id
  WHERE program.user_id = ?", user_id)
  
  slim(:"/program/index", locals: { programs: programs })
end