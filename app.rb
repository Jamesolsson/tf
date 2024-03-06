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

  rescue SQLite3::ConstraintException => e
 
  session[:error] = "Exercise already added"

  redirect('/protected/exercises')
end

post("/create")do

  name = params[:name]
  muscle_grupp = params[:muscle_grupp]

  db = SQLite3::Database.new('db/gymi.db')
  db.execute("INSERT INTO exercises (name, muscle_grupp) VALUES (?, ?);", name, muscle_grupp)

  redirect('/protected/exercises')
end


get('/user/exercises') do
  user_id = session[:id]


  db = SQLite3::Database.new('db/gymi.db')
  db.results_as_hash = true
  user_exercises = db.execute("SELECT exercises.name, exercises.muscle_grupp FROM exercises INNER JOIN users_exercises_rel ON exercises.id = users_exercises_rel.exercises_id WHERE users_exercises_rel.user_id = ? ORDER BY muscle_grupp ASC;", user_id)

  slim(:"exercises/user_exercises", locals: { user_exercises: user_exercises })

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
  slim(:"/program/index")
end
  

