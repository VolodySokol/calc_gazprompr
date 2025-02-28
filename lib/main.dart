
// material.dart – создания пользовательского интерфейса 
// math_expressions – парсинг и вычисление математических выражений
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter/services.dart';


void main() {
  runApp(CalculatorApp());
}


// CalculatorApp объявляется как StatelessWidget, неизменяемый
class CalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // MaterialApp – базовый виджет для Material Design приложений
    // debugShowCheckedModeBanner отключает отладочный баннер
    // home задаёт главный экран приложения – здесь он будет CalculatorScreen
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalculatorScreen(),
    );
  }
}

// Экран калькулятора объявляется как StatefulWidget, изменяемый (ввод выражения, результат и т.д.).
class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}


class _CalculatorScreenState extends State<CalculatorScreen> {
  String input = ""; // Строка для хранения текущего выражения
  String output = "0"; // Результат вычисления выражения
  int openParentheses = 0; // Счётчик открытых скобок
  final TextEditingController _controller = TextEditingController(); // Контроллер для управления текстовым полем

  // initState вызывается при создании виджета. Задаем начальное значение для текстового поля
  @override
  void initState() {
    super.initState();
    _controller.text = input;
  }

  // dispose вызывается при уничтожении виджета, освобождаем ресурсы, связанные с _controller
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  // функция обновляет строку input, меняет счетчик скобок и следит за текстовым полем
  void _onButtonPressed(String value) {
    setState(() {
      // Очищаем все поля и сбрасываем счетчик скобок
      if (value == "C") {
        input = "";
        output = "0";
        openParentheses = 0;
      }
      // удаляем последний символ
      else if (value == "⌫") {
        if (input.isNotEmpty) {
          if (input.endsWith("(")) openParentheses--;
          if (input.endsWith(")")) openParentheses++;
          input = input.substring(0, input.length - 1); 
        }
      }
      else if (value == "=") {
        _calculate();
      }
      // вставляем либо открывающую, либо закрывающую скобку
      else if (value == "()") {
        if (openParentheses == 0 ||
            input.isEmpty ||
            "+-*/(".contains(input[input.length - 1])) {
          input += "(";
          openParentheses++;
        } else if (openParentheses > 0) {
          input += ")";
          openParentheses--;
        }
      }
      // преобразуем последнее число в процентное выражение
      else if (value == "%") {
        input = input.replaceAllMapped(
            RegExp(r'(\d+)$'), (match) => '(${match.group(1)} * 0.01)');
      }
      // обрабатываем ввод десятичной точки
      else if (value == ".") {
        RegExp lastNumber = RegExp(r'(\d+\.\d*)$');
        if (input.isEmpty || !RegExp(r'\d$').hasMatch(input)) {
          input += "0."; 
        } else if (!lastNumber.hasMatch(input)) {
          input += ".";
        }
      }
      // Для всех остальных кнопок
      else {
        if ("+-*/".contains(value) && input.isNotEmpty && "+-*/".contains(input[input.length - 1])) {
          input = input.substring(0, input.length - 1) + value;
        } else {
          input += value;
        }
      }
      
      // Обнова текста и курсора
      _controller.text = input;
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length));
    });
  }

  // Функция вычисления введенного выражения
  // очищает выражение,
  // вставляет умножение там, где нужно (например, "4(7+9)"),
  // парсит выражение и вычисляет с math_expressions.
  void _calculate() {
    try {
      // Работа со скобками
      if (openParentheses > 0) return;
      // Удаляем завершающие операторы
      String sanitizedInput = input.replaceAll(RegExp(r'[\+\-\*/]$'), '');
      if (sanitizedInput.isEmpty) return;

      // Преобразуем выражения вида "4(7+9)" в "4*(7+9)".
      sanitizedInput = sanitizedInput.replaceAllMapped(
          RegExp(r'(\d)\('), (match) => '${match.group(1)}*(');
      print("Преобразованное выражение: $sanitizedInput");

      Parser p = Parser();
      // Парсим строку в математическое выражение
      Expression exp = p.parse(sanitizedInput);
      // Создаем контекст 
      ContextModel cm = ContextModel();

      double result = exp.evaluate(EvaluationType.REAL, cm);

      // Обновляем результат
      setState(() {
        output = result.toString();
      });
    } catch (e) {
      setState(() {
        output = "Ошибка";
      });
    }
  }

  // Создание строки с кнопками калькулятора
  Widget _buildButtonRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((value) => _buildButton(value)).toList(),
    );
  }

  // Создание кнопок калькулятора
  Widget _buildButton(String value) {
    return GestureDetector(
      onTap: () {
        _onButtonPressed(value);
      },
      child: Container(
        margin: EdgeInsets.all(8), // Отступ вокруг кнопки
        width: 80, // Ширина кнопки
        height: 80, // Высота кнопки
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[700]!, Colors.grey[900]!], // Градиент кнопки
          ),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2)), // Тень кнопки
          ],
          borderRadius: BorderRadius.circular(10), // Скругленные углы кнопки
        ),
        child: Center(
          child: Text(
            value, // Текст, отображаемый на кнопке
            style: TextStyle(fontSize: 32, color: Colors.white), // Стиль текста
          ),
        ),
      ),
    );
  }

  // Метод build, формирует весь интерфейс экрана калькулятора.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Фоновый цвет экрана.
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Располагаем элементы сверху вниз.
        children: [
          // Блок с текстовым полем для ввода выражения.
          Container(
            padding: EdgeInsets.all(20),
            child: TextField(
              controller: _controller, 
              style: TextStyle(fontSize: 32, color: Colors.white), // Стиль вводимого текста.
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange, width: 2.0), 
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange, width: 2.0), 
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange, width: 2.0), 
                ),
                hintText: "Введите выражение", 
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true), 
              onChanged: (value) {
                setState(() {
                  input = value; // Обновляем переменную input при изменении текста.
                });
              },
              onSubmitted: (value) {
                // вывод ри нажатии Enter
                _calculate();
              },
            ),
          ),
          // Блок ывода результата 
          Container(
            padding: EdgeInsets.all(20),
            alignment: Alignment.centerRight, // Выравнивание текста результата по правому краю.
            child: Text(
              output, 
              style: TextStyle(fontSize: 48, color: Colors.orange), // цвет
            ),
          ),
          Divider(color: Colors.white), // Разделительная линия между полем ввода/результатом и кнопками.
          // Блок с кнопками 
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, 
              children: [
                _buildButtonRow(["C", "()", "%", "/"]), 
                _buildButtonRow(["7", "8", "9", "*"]),   
                _buildButtonRow(["4", "5", "6", "-"]),   
                _buildButtonRow(["1", "2", "3", "+"]),  
                _buildButtonRow(["0", ".", "⌫", "="]),     
              ],
            ),
          ),
        ],
      ),
    );
  }
}
