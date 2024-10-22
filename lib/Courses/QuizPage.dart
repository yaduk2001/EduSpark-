import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class QuizPage extends StatefulWidget {
  final String courseName;
  final String userID;

  QuizPage({required this.courseName, required this.userID});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Question> questions = [];
  Map<int, String> userAnswers = {};
  bool isLoading = true;
  bool quizSubmitted = false;
  int score = 0;

  final String bingApiKey = '1f9eb51f009d49f0ab49551c77ae8793';
  final int totalQuestions = 10;

  @override
  void initState() {
    super.initState();
    showWelcomeDialog();
  }

  void showWelcomeDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Good Luck!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Text('Best of luck for the quiz. Proceed to ace it!', style: GoogleFonts.poppins()),
            actions: <Widget>[
              TextButton(
                child: Text('Start Quiz', style: GoogleFonts.poppins()),
                onPressed: () {
                  Navigator.of(context).pop();
                  generateQuestions();
                },
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> generateQuestions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final searchResults = await searchBing(widget.courseName);
      questions = await createQuestionsFromSearchResults(searchResults);
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error generating questions: $e');
      showNoQuestionsDialog();
    }
  }

  Future<List<String>> searchBing(String query) async {
    final url = Uri.parse('https://api.bing.microsoft.com/v7.0/search?q=$query&count=5');
    final response = await http.get(
      url,
      headers: {'Ocp-Apim-Subscription-Key': bingApiKey},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['webPages']['value']
          .map<String>((result) => result['snippet'] as String)
          .toList();
    } else {
      throw Exception('Failed to load search results');
    }
  }

  Future<List<Question>> createQuestionsFromSearchResults(List<String> searchResults) async {
    List<Question> generatedQuestions = [];

    for (var snippet in searchResults) {
      if (generatedQuestions.length >= totalQuestions) break;

      // Use the snippet to create a question
      final question = await createQuestionFromSnippet(snippet);
      if (question != null) {
        generatedQuestions.add(question);
      }
    }

    return generatedQuestions;
  }

  Future<Question?> createQuestionFromSnippet(String snippet) async {
    // This is a simple example. You might want to use a more sophisticated method
    // to generate questions, possibly using another API or a local algorithm.
    final sentences = snippet.split('. ');
    if (sentences.isEmpty) return null;

    final questionText = 'Which of the following is true about ${widget.courseName}?';
    final correctAnswer = sentences[0];
    final wrongAnswers = sentences.sublist(1);

    List<String> options = [correctAnswer, ...wrongAnswers];
    options.shuffle();

    if (options.length < 4) {
      // If we don't have enough options, add some generic wrong answers
      options.addAll([
        'None of the above',
        'All of the above',
        'This statement is false',
      ]);
    }

    options = options.take(4).toList();

    return Question(
      question: questionText,
      options: options,
      correctAnswer: correctAnswer,
    );
  }

  void showNoQuestionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('No Questions Available'),
        content: Text('Unable to generate questions for this course. Please try again later.'),
        actions: [
          TextButton(
            child: Text('Go Back'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pop(); // Go back to the previous screen
            },
          ),
        ],
      ),
    );
  }

  void submitQuiz() {
    setState(() {
      quizSubmitted = true;
      score = calculateScore();
    });

    double percentage = (score / questions.length) * 100;
    bool passed = percentage >= 70;

    FirebaseFirestore.instance.collection('quizResults').add({
      'userID': widget.userID,
      'courseName': widget.courseName,
      'score': score,
      'totalQuestions': questions.length,
      'percentage': percentage,
      'passed': passed,
      'timestamp': FieldValue.serverTimestamp(),
    });

    showResultDialog(passed, percentage);
  }

  void showResultDialog(bool passed, double percentage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            passed ? 'Congratulations!' : 'Better Luck Next Time',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: passed ? Colors.green : Colors.red),
          ),
          content: Text(
            passed
                ? 'You passed the quiz with ${percentage.toStringAsFixed(1)}%!'
                : 'You scored ${percentage.toStringAsFixed(1)}%. 70% is required to pass.',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: GoogleFonts.poppins()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  int calculateScore() {
    int correctAnswers = 0;
    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] == questions[i].correctAnswer) {
        correctAnswers++;
      }
    }
    return correctAnswers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.courseName}', style: GoogleFonts.poppins()),
        backgroundColor: Colors.indigo,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : questions.isEmpty
              ? Center(child: Text('No questions available', style: GoogleFonts.poppins()))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...questions.asMap().entries.map((entry) {
                          int idx = entry.key;
                          Question question = entry.value;
                          return buildQuestionCard(idx, question);
                        }).toList(),
                        SizedBox(height: 20),
                        if (!quizSubmitted)
                          ElevatedButton(
                            child: Text('Submit Quiz', style: GoogleFonts.poppins()),
                            onPressed: submitQuiz,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: EdgeInsets.symmetric(vertical: 15),
                            ),
                          )
                        else
                          ResultCard(score: score, totalQuestions: questions.length),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget buildQuestionCard(int index, Question question) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(question.question, style: GoogleFonts.poppins(fontSize: 16)),
            SizedBox(height: 12),
            ...question.options.map((option) => 
              RadioListTile<String>(
                title: Text(option, style: GoogleFonts.poppins()),
                value: option,
                groupValue: userAnswers[index],
                onChanged: quizSubmitted ? null : (value) {
                  setState(() {
                    userAnswers[index] = value!;
                  });
                },
                activeColor: quizSubmitted
                    ? (option == question.correctAnswer ? Colors.green : Colors.red)
                    : Colors.indigo,
              ),
            ),
            if (quizSubmitted && userAnswers[index] != question.correctAnswer)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Correct answer: ${question.correctAnswer}',
                  style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  final int score;
  final int totalQuestions;

  ResultCard({required this.score, required this.totalQuestions});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.indigo,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Quiz Completed!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Your Score',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70),
            ),
            Text(
              '$score / $totalQuestions',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Great job! Keep learning and improving.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class Question {
  final String question;
  final List<String> options;
  final String correctAnswer;

  Question({required this.question, required this.options, required this.correctAnswer});
}
