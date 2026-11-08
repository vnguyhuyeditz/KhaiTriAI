import '../models/question.dart';

/// 20 câu Toán 10 viết tay: mỗi tiêu chí 5 câu.
/// Dùng khi chưa có AI, hoặc làm phương án dự phòng khi AI lỗi.
final List<Question> sampleQuestions = [
  // ===== GHI NHỚ =====
  Question(
    id: 't01',
    text: 'Với phương trình bậc hai ax² + bx + c = 0 (a ≠ 0), '
        'biệt thức Δ được tính bằng công thức nào?',
    options: ['Δ = b² + 4ac', 'Δ = b² − 4ac', 'Δ = 4ac − b²', 'Δ = b² − 2ac'],
    correct: 1,
    criterion: Criterion.nho,
    explanation: 'Δ = b² − 4ac. Dấu của Δ cho biết số nghiệm của phương trình.',
    misconceptions: {
      0: 'Nhầm dấu: Δ là b² TRỪ 4ac.',
      2: 'Đảo thứ tự hai số hạng.',
      3: 'Nhầm hệ số 4ac thành 2ac.',
    },
  ),
  Question(
    id: 't02',
    text: 'Kí hiệu ℤ dùng để chỉ tập hợp nào?',
    options: [
      'Tập số tự nhiên',
      'Tập số hữu tỉ',
      'Tập số thực',
      'Tập số nguyên',
    ],
    correct: 3,
    criterion: Criterion.nho,
    explanation: 'ℤ là tập số nguyên: ..., −2, −1, 0, 1, 2, ...',
    misconceptions: {
      0: 'ℕ mới là tập số tự nhiên.',
      1: 'ℚ mới là tập số hữu tỉ.',
      2: 'ℝ mới là tập số thực.',
    },
  ),
  Question(
    id: 't03',
    text: 'Trong tam giác ABC, định lí côsin cho biết a² bằng:',
    options: [
      'b² + c² − 2bc·cosA',
      'b² + c² + 2bc·cosA',
      'b² + c² − 2bc·sinA',
      'b² − c² − 2bc·cosA',
    ],
    correct: 0,
    criterion: Criterion.nho,
    explanation: 'a² = b² + c² − 2bc·cosA. Khi A = 90° thì cosA = 0 '
        'và ta được định lí Pytago.',
    misconceptions: {
      1: 'Sai dấu của số hạng 2bc·cosA.',
      2: 'Dùng sin thay cho cos.',
      3: 'Sai dấu trước c².',
    },
  ),
  Question(
    id: 't04',
    text: 'Hoành độ đỉnh của parabol y = ax² + bx + c (a ≠ 0) là:',
    options: ['x = b/(2a)', 'x = −b/a', 'x = −b/(2a)', 'x = −2b/a'],
    correct: 2,
    criterion: Criterion.nho,
    explanation: 'Hoành độ đỉnh là x = −b/(2a).',
    misconceptions: {
      0: 'Thiếu dấu trừ.',
      1: 'Thiếu hệ số 2 ở mẫu.',
      3: 'Nhầm công thức.',
    },
  ),
  Question(
    id: 't05',
    text: 'Giá trị của sin 30° bằng:',
    options: ['√3/2', '√2/2', '1', '1/2'],
    correct: 3,
    criterion: Criterion.nho,
    explanation: 'sin 30° = 1/2.',
    misconceptions: {
      0: '√3/2 là sin 60°.',
      1: '√2/2 là sin 45°.',
      2: '1 là sin 90°.',
    },
  ),

  // ===== HIỂU BẢN CHẤT =====
  Question(
    id: 't06',
    text: 'Mệnh đề phủ định của “∀x ∈ ℝ, x² ≥ 0” là:',
    options: [
      '∀x ∈ ℝ, x² < 0',
      '∃x ∈ ℝ, x² < 0',
      '∃x ∈ ℝ, x² ≤ 0',
      '∀x ∈ ℝ, x² ≤ 0',
    ],
    correct: 1,
    criterion: Criterion.hieu,
    explanation: 'Phủ định đổi ∀ thành ∃ và đổi “≥” thành “<”.',
    misconceptions: {
      0: 'Phủ định của ∀ phải đổi thành ∃.',
      2: 'Phủ định của “≥” là “<”, không phải “≤”.',
      3: 'Sai cả lượng từ lẫn dấu bất đẳng thức.',
    },
  ),
  Question(
    id: 't07',
    text: 'Cho A = {1; 2; 3} và B = {2; 3; 4}. Tập hợp A ∩ B là:',
    options: ['{1; 2; 3; 4}', '{2; 3}', '{1}', '{4}'],
    correct: 1,
    criterion: Criterion.hieu,
    explanation: 'A ∩ B gồm các phần tử thuộc cả A và B, tức {2; 3}.',
    misconceptions: {
      0: 'Đây là A ∪ B (hợp), không phải giao.',
      2: 'Đây là A \\ B.',
      3: 'Đây là B \\ A.',
    },
  ),
  Question(
    id: 't08',
    text: 'Parabol y = −x² + 2x + 3 có bề lõm hướng nào, và vì sao?',
    options: [
      'Hướng lên, vì a < 0',
      'Hướng xuống, vì c > 0',
      'Hướng xuống, vì a < 0',
      'Hướng lên, vì b > 0',
    ],
    correct: 2,
    criterion: Criterion.hieu,
    explanation: 'Dấu của a quyết định hướng bề lõm: a < 0 thì hướng xuống.',
    misconceptions: {
      0: 'Nếu a < 0 thì bề lõm hướng xuống, không phải lên.',
      1: 'Hướng bề lõm do dấu của a quyết định, không phải c.',
      3: 'Dấu của b không quyết định hướng bề lõm.',
    },
  ),
  Question(
    id: 't09',
    text: 'Với a > 0, nếu Δ < 0 thì parabol y = ax² + bx + c '
        'so với trục hoành như thế nào?',
    options: [
      'Cắt trục hoành tại hai điểm phân biệt',
      'Tiếp xúc với trục hoành',
      'Cắt trục hoành tại đúng một điểm',
      'Nằm hoàn toàn phía trên trục hoành',
    ],
    correct: 3,
    criterion: Criterion.hieu,
    explanation: 'Δ < 0 nghĩa là phương trình ax² + bx + c = 0 vô nghiệm, '
        'nên parabol không cắt trục hoành. Vì a > 0 nên nó nằm phía trên.',
    misconceptions: {
      0: 'Hai giao điểm xảy ra khi Δ > 0.',
      1: 'Tiếp xúc xảy ra khi Δ = 0.',
      2: 'Một điểm chung là trường hợp tiếp xúc (Δ = 0).',
    },
  ),
  Question(
    id: 't10',
    text: 'Hai vectơ được gọi là bằng nhau khi nào?',
    options: [
      'Cùng độ dài',
      'Cùng hướng và cùng độ dài',
      'Cùng phương',
      'Cùng điểm đầu',
    ],
    correct: 1,
    criterion: Criterion.hieu,
    explanation: 'Hai vectơ bằng nhau khi cùng hướng và cùng độ dài.',
    misconceptions: {
      0: 'Cùng độ dài nhưng khác hướng thì không bằng nhau.',
      2: 'Cùng phương chưa đủ, còn cần cùng hướng và cùng độ dài.',
      3: 'Điểm đầu không liên quan đến việc hai vectơ bằng nhau.',
    },
  ),

  // ===== VẬN DỤNG =====
  Question(
    id: 't11',
    text: 'Nghiệm của phương trình x² − 5x + 6 = 0 là:',
    options: [
      'x = −2 hoặc x = −3',
      'x = 1 hoặc x = 6',
      'x = 2 hoặc x = 3',
      'x = −1 hoặc x = −6',
    ],
    correct: 2,
    criterion: Criterion.vanDung,
    explanation: 'Δ = 25 − 24 = 1, nên x = (5 ± 1)/2, tức x = 2 hoặc x = 3.',
    misconceptions: {
      0: 'Tổng hai nghiệm phải là +5 (bằng −b/a), không phải −5.',
      1: 'Tích bằng 6 nhưng tổng là 7, không phải 5.',
      3: 'Sai dấu cả hai nghiệm.',
    },
  ),
  Question(
    id: 't12',
    text: 'Tam giác ABC vuông tại A có AB = 3 và AC = 4. Độ dài BC là:',
    options: ['7', '5', '25', '1'],
    correct: 1,
    criterion: Criterion.vanDung,
    explanation: 'BC² = 3² + 4² = 25 nên BC = 5.',
    misconceptions: {
      0: 'Cộng hai cạnh góc vuông thay vì dùng định lí Pytago.',
      2: 'Quên lấy căn bậc hai: BC² = 25 nên BC = 5.',
      3: 'Lấy hiệu thay vì dùng định lí Pytago.',
    },
  ),
  Question(
    id: 't13',
    text: 'Đỉnh của parabol y = x² − 4x + 1 là:',
    options: ['(−2; 13)', '(2; 3)', '(4; 1)', '(2; −3)'],
    correct: 3,
    criterion: Criterion.vanDung,
    explanation: 'x = −b/(2a) = 4/2 = 2; y = 2² − 4·2 + 1 = −3. '
        'Vậy đỉnh là (2; −3).',
    misconceptions: {
      0: 'Sai dấu hoành độ đỉnh: x = −b/(2a) = 2.',
      1: 'Hoành độ đúng nhưng tính sai tung độ: y = 4 − 8 + 1 = −3.',
      2: 'Nhầm với hệ số của phương trình.',
    },
  ),
  Question(
    id: 't14',
    text: 'Tập nghiệm của bất phương trình 2x − 6 > 0 là:',
    options: ['x < 3', 'x > −3', 'x > 3', 'x > 12'],
    correct: 2,
    criterion: Criterion.vanDung,
    explanation: '2x > 6 nên x > 3.',
    misconceptions: {
      0: 'Đảo chiều dấu bất đẳng thức khi không chia cho số âm.',
      1: 'Sai dấu khi chuyển vế.',
      3: 'Nhân thay vì chia khi chuyển vế.',
    },
  ),
  Question(
    id: 't15',
    text: 'Cho A(1; 2) và B(3; 6). Tọa độ vectơ AB là:',
    options: ['(4; 8)', '(2; 4)', '(−2; −4)', '(2; 8)'],
    correct: 1,
    criterion: Criterion.vanDung,
    explanation: 'Vectơ AB = (3 − 1; 6 − 2) = (2; 4).',
    misconceptions: {
      0: 'Đã cộng tọa độ; vectơ AB = B − A.',
      2: 'Nhầm thứ tự: đây là tọa độ vectơ BA.',
      3: 'Chỉ tính đúng hoành độ.',
    },
  ),

  // ===== PHÂN TÍCH =====
  Question(
    id: 't16',
    text: 'Một bạn giải x² = 4 và viết “x = 2”. Lỗi sai của bạn ấy là gì?',
    options: [
      'Tính sai giá trị 2²',
      'Phương trình này vô nghiệm',
      'Bỏ sót nghiệm x = −2',
      'Bài giải không có lỗi',
    ],
    correct: 2,
    criterion: Criterion.phanTich,
    explanation: 'x² = 4 có hai nghiệm x = 2 và x = −2.',
    misconceptions: {
      0: '2² = 4 là đúng.',
      1: 'x² = 4 có hai nghiệm x = ±2.',
      3: 'Bài giải thiếu nghiệm x = −2 nên chưa đầy đủ.',
    },
  ),
  Question(
    id: 't17',
    text: 'Mệnh đề “∀x ∈ ℝ, x² > x” đúng hay sai?',
    options: [
      'Đúng, vì bình phương luôn lớn hơn số ban đầu',
      'Đúng, vì x² ≥ 0',
      'Sai, vì với x = 0,5 thì x² < x',
      'Sai, vì với x = −1 thì x² < x',
    ],
    correct: 2,
    criterion: Criterion.phanTich,
    explanation: 'Với x = 0,5 ta có x² = 0,25 < 0,5 = x, nên mệnh đề sai.',
    misconceptions: {
      0: 'Với 0 < x < 1 thì x² < x.',
      1: 'x² ≥ 0 không suy ra được x² > x.',
      3: 'Với x = −1 thì x² = 1 > −1, nên đây không phải phản ví dụ.',
    },
  ),
  Question(
    id: 't18',
    text: 'Tam giác ABC có BC = 5, CA = 4, AB = 3. Đây là tam giác gì?',
    options: [
      'Tam giác nhọn',
      'Tam giác tù',
      'Tam giác vuông tại B',
      'Tam giác vuông tại A',
    ],
    correct: 3,
    criterion: Criterion.phanTich,
    explanation: 'BC² = 25 = 16 + 9 = CA² + AB², nên tam giác vuông tại A '
        '(đối diện cạnh dài nhất).',
    misconceptions: {
      0: 'Vì 3² + 4² = 5² nên tam giác có góc vuông.',
      1: 'Vì 3² + 4² = 5² nên không phải tam giác tù.',
      2: 'Góc vuông nằm đối diện cạnh dài nhất (BC), tức tại A.',
    },
  ),
  Question(
    id: 't19',
    text: 'Gọi m là giá trị nhỏ nhất của f(x) = x² − 4x + 1 và M là giá trị '
        'lớn nhất của g(x) = −f(x). Cặp (m; M) là:',
    options: ['(−3; −3)', '(3; 3)', '(3; −3)', '(−3; 3)'],
    correct: 3,
    criterion: Criterion.phanTich,
    explanation: 'f có giá trị nhỏ nhất m = −3 (tại x = 2). '
        'g = −f nên giá trị lớn nhất của g là M = 3.',
    misconceptions: {
      0: 'g = −f nên giá trị lớn nhất của g bằng −m = 3.',
      1: 'Sai dấu của m: giá trị nhỏ nhất của f là −3.',
      2: 'Đảo ngược cả hai giá trị.',
    },
  ),
  Question(
    id: 't20',
    text: 'Mệnh đề “Nếu a² > b² thì a > b” đúng hay sai?',
    options: [
      'Đúng, vì với a = 3, b = 1 thì cả hai vế đều đúng',
      'Đúng, vì bình phương giữ nguyên thứ tự',
      'Sai, vì với a = −3, b = 1 thì a² > b² nhưng a < b',
      'Sai, vì với a = 3, b = 1 thì a < b',
    ],
    correct: 2,
    criterion: Criterion.phanTich,
    explanation: 'Với a = −3, b = 1: a² = 9 > 1 = b² nhưng a = −3 < 1 = b. '
        'Đó là phản ví dụ nên mệnh đề sai.',
    misconceptions: {
      0: 'Một ví dụ thỏa mãn không chứng minh được mệnh đề đúng với mọi a, b.',
      1: 'Bình phương chỉ giữ thứ tự khi cả hai số không âm.',
      3: 'Với a = 3, b = 1 thì a > b, nên đây không phải phản ví dụ.',
    },
  ),
];
