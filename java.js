const newExerciseButton = document.getElementById("add_new_exercise_button");
const exerciseContainer = document.getElementById("exercises");

function addExercise() {
  let newExercise = document.createElement("div");
  newExercise.innerHTML = `
        <input type="text" name="exercise[]" placeholder="exercise">
        <input type="number" name="sets[]" placeholder="sets">
        <input type="number" name="reps[]" placeholder="reps">
    `;
  exerciseContainer.appendChild(newExercise);
}

newExerciseButton.addEventListener("click", addExercise);