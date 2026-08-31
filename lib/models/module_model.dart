import 'package:flutter/material.dart';
import 'lesson_model.dart';

/// A top-level module in the "Matuto" section (e.g. "Modyul 1:
/// Alpabeto at Numero"). Each module groups one or more [LessonModel]s
/// — see mockup screens 5 (module list) and 6 (a module's lessons).
class ModuleModel {
  final String id;
  final String number; // "Modyul 1"
  final String title; // "Alpabeto at Numero"
  final IconData icon;
  final List<LessonModel> lessons;

  const ModuleModel({
    required this.id,
    required this.number,
    required this.title,
    required this.icon,
    required this.lessons,
  });
}

/// ---------------------------------------------------------------
/// DUMMY MODULE CONTENT
///
/// Placeholder so the module/lesson/quiz flow can be built and
/// tested end-to-end before real FSL video content and
/// FSL-advocate-verified descriptions are ready. Swap the `lessons`
/// lists below (or replace this whole file) once real content
/// exists — nothing in the UI layer needs to change, every screen
/// just reads from [kModules].
///
/// Module order/titles follow the mockup's 4-module list (Modyul 1:
/// Alpabeto at Numero, Modyul 2, Modyul 3: Mga Pagbati, Modyul 4:
/// Panghalip). Modyul 2's title wasn't fully legible in the mockup
/// screenshot, so "Mga Kulay" (Colors) is a placeholder guess — swap
/// it for whatever the real topic is.
/// ---------------------------------------------------------------

final List<ModuleModel> kModules = [
  ModuleModel(
    id: 'modyul_1',
    number: 'Modyul 1',
    title: 'Alpabeto at Numero',
    icon: Icons.abc_rounded,
    lessons: const [
      LessonModel(
        id: 'alpabeto',
        title: 'Alpabeto',
        signs: [
          SignModel(
            id: 'a',
            label: 'A',
            meaning: 'Titik A',
            description:
                'Ang senyas para sa letrang A ay ginagawa sa pamamagitan ng '
                'pagbuo ng kamao, habang ang hinlalaki ay nakalapat sa gilid '
                'ng hintuturo. (Dummy na paglalarawan.)',
          ),
          SignModel(
            id: 'b',
            label: 'B',
            meaning: 'Titik B',
            description:
                'Dummy na paglalarawan para sa letrang B. Papalitan ito ng '
                'aktwal na paglalarawan mula sa FSL advocate.',
          ),
          SignModel(
            id: 'c',
            label: 'C',
            meaning: 'Titik C',
            description:
                'Dummy na paglalarawan para sa letrang C. Papalitan ito ng '
                'aktwal na paglalarawan mula sa FSL advocate.',
          ),
        ],
        quiz: [
          QuizQuestionModel(
            question: 'Anong letra ito?',
            signLabel: 'A',
            options: ['A', 'C', 'B', 'E'],
            correctIndex: 0,
          ),
          QuizQuestionModel(
            question: 'Anong letra ito?',
            signLabel: 'B',
            options: ['A', 'C', 'B', 'E'],
            correctIndex: 2,
          ),
          QuizQuestionModel(
            question: 'Anong letra ito?',
            signLabel: 'C',
            options: ['A', 'C', 'B', 'E'],
            correctIndex: 1,
          ),
        ],
      ),
      LessonModel(
        id: 'numero',
        title: 'Numero',
        signs: [
          SignModel(
            id: 'isa',
            label: 'Isa',
            meaning: '1',
            description: 'Dummy na paglalarawan para sa senyas ng "Isa".',
          ),
          SignModel(
            id: 'dalawa',
            label: 'Dalawa',
            meaning: '2',
            description: 'Dummy na paglalarawan para sa senyas ng "Dalawa".',
          ),
        ],
        quiz: [
          QuizQuestionModel(
            question: 'Anong numero ito?',
            signLabel: 'Isa',
            options: ['Isa', 'Dalawa', 'Tatlo', 'Apat'],
            correctIndex: 0,
          ),
          QuizQuestionModel(
            question: 'Anong numero ito?',
            signLabel: 'Dalawa',
            options: ['Isa', 'Dalawa', 'Tatlo', 'Apat'],
            correctIndex: 1,
          ),
        ],
      ),
    ],
  ),
  ModuleModel(
    id: 'modyul_2',
    number: 'Modyul 2',
    title: 'Mga Kulay', // placeholder guess — see note above
    icon: Icons.palette_rounded,
    lessons: const [
      LessonModel(
        id: 'kulay',
        title: 'Mga Kulay',
        signs: [
          SignModel(
            id: 'pula',
            label: 'Pula',
            meaning: 'Red',
            description: 'Dummy na paglalarawan para sa senyas ng "Pula".',
          ),
          SignModel(
            id: 'asul',
            label: 'Asul',
            meaning: 'Blue',
            description: 'Dummy na paglalarawan para sa senyas ng "Asul".',
          ),
        ],
        quiz: [
          QuizQuestionModel(
            question: 'Anong kulay ito?',
            signLabel: 'Pula',
            options: ['Pula', 'Asul', 'Dilaw', 'Berde'],
            correctIndex: 0,
          ),
          QuizQuestionModel(
            question: 'Anong kulay ito?',
            signLabel: 'Asul',
            options: ['Pula', 'Asul', 'Dilaw', 'Berde'],
            correctIndex: 1,
          ),
        ],
      ),
    ],
  ),
  ModuleModel(
    id: 'modyul_3',
    number: 'Modyul 3',
    title: 'Mga Pagbati',
    icon: Icons.waving_hand_rounded,
    lessons: const [
      LessonModel(
        id: 'pagbati',
        title: 'Mga Pagbati',
        signs: [
          SignModel(
            id: 'magandang_umaga',
            label: 'Magandang Umaga',
            meaning: 'Good Morning',
            description:
                'Dummy na paglalarawan para sa senyas ng "Magandang Umaga".',
          ),
        ],
        quiz: [
          QuizQuestionModel(
            question: 'Anong pagbati ito?',
            signLabel: 'Magandang Umaga',
            options: ['Magandang Gabi', 'Magandang Umaga', 'Paalam', 'Salamat'],
            correctIndex: 1,
          ),
        ],
      ),
    ],
  ),
  ModuleModel(
    id: 'modyul_4',
    number: 'Modyul 4',
    title: 'Panghalip',
    icon: Icons.people_alt_rounded,
    lessons: const [
      LessonModel(
        id: 'panghalip',
        title: 'Panghalip',
        signs: [
          SignModel(
            id: 'ako',
            label: 'Ako',
            meaning: 'I / Me',
            description: 'Dummy na paglalarawan para sa senyas ng "Ako".',
          ),
        ],
        quiz: [
          QuizQuestionModel(
            question: 'Anong panghalip ito?',
            signLabel: 'Ako',
            options: ['Ikaw', 'Siya', 'Ako', 'Kami'],
            correctIndex: 2,
          ),
        ],
      ),
    ],
  ),
];
