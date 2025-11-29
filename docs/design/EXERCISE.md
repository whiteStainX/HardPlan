This summary details the primary and secondary muscle groups targeted by various movement patterns, drawing from the volume calculation logic and exercise classification found in the sources. The "Overlap Rule" is used internally to accurately track sets per muscle group by assigning a factor (1.0 for primary, and a fractional factor for secondary) to ensure accurate volume tracking (10–20 sets/week guidelines).

## Muscle Group Mappings for Common Movement Patterns

The table below lists the primary and secondary muscles, along with the coefficient (impact factor) used in calculating training volume, based on the standard mappings required by the algorithm logic:

| Movement Pattern | Primary Muscle (Factor 1.0) | Secondary Muscles (Impact Factor) |
| :--- | :--- | :--- |
| **Squat Pattern** | **Quads** | **Glutes** (1.0), Adductors (0.5), Spinal Erectors / Lower Back (0.5) |
| **Bench Press Pattern** | **Chest** | **Front Delt** (1.0), Triceps (0.75) |
| **Deadlift Pattern** | **Hamstrings**, **Glutes**, **Spinal Erectors / Lower Back** | Quads (0.5), Traps (0.5), Forearms (0.5) |
| **Row Pattern** | **Lats**, **Rhomboids** | Rear Delt (0.5), Biceps (0.5) |

*Note: In the exercise database examples, the Barbell Back Squat has slightly different factors listed: Glutes (0.8), Hamstrings (0.6), and Back\_Lower (0.4). The Barbell Bench Press has Front Delts (0.6) and Triceps (0.7).*

## General Hypertrophy Movement Patterns

For hypertrophy training and exercise selection, the muscle groups are categorized based on movement planes, ensuring balanced development (1–2 compound and 1–3 isolation movements per major muscle group):

| Movement Pattern | Primary Muscle Groups | Secondary Muscle Groups | Examples |
| :--- | :--- | :--- | :--- |
| **Squat** | **Quads, Glutes** | Erectors (if free weights) | Barbell Squat, Leg Press, Lunges |
| **Hip Hinge** | **Glutes, Hams, Erectors** | Scapular Retractors | Deadlift Variations, Good Mornings |
| **Vertical Pull** | **Lats, Bis** | Rear Delts, Rhomboids | Pull-ups, Chin-ups, Lat Pulldowns |
| **Vertical Push** | **Anterior Delts, Tris** | Middle Delts | OHP Variations (Barbell, Dumbbell) |
| **Horizontal Pull** | **Lats, Scapular Retractors** | Rear Delts, Bis | Barbell Row, Dumbbell Row, Cable Row |
| **Horizontal Push** | **Chest, Anterior Delts** | Tris (CG/dips: primary) | Bench Press (BB, DB), Incline Press |
| **Horizontal Hip Extension** | **Glutes** | Hams | Hip Thrust, Glute Bridge |
| **Fly** | **Chest** | Anterior Delts | Cable Crossover, Dumbbell Flys |
| **Core / Abs** | **Abs** | Obliques | Cable Crunches, Leg Raises, Planks |
| **Calves** | **Calves** | | Calf Raises (Seated, Standing) |
| **Biceps / Triceps** | **Biceps / Triceps** | | Curls, Pushdowns, Extensions |
| **Other Isolation** | **Target muscle** | N/A | Lateral Raises, Leg Extensions, etc. |

## Specific Isolation Exercise Mappings

The exercise database provides specific mappings for various isolation and machine movements, often used as accessory lifts (where load increases are harder, suited for Double Progression):

| Exercise Name | Primary Muscle | Secondary Muscles (Impact Factor) |
| :--- | :--- | :--- |
| **Leg Extension** (Machine) | **Quads** | None |
| **Leg Curl** (Machine) | **Hamstrings** | Calves (0.2) |
| **Dumbbell Lateral Raise** | **Delts\_Side** | Delts\_Rear (0.2) |
| **Cable Tricep Pushdown** | **Triceps** | Delts\_Front (0.2) |
| **Dumbbell Bicep Curl** | **Biceps** | None |
| **Cable Crunch** | **Abs** | None |
| **Barbell Overhead Press (OHP)** | **Delts\_Front** | Delts\_Side (0.6), Triceps (0.7) |
| **Barbell Row** | **Back\_Lats** | Back\_Traps (0.6), Biceps (0.5), Back\_Lower (0.3) |