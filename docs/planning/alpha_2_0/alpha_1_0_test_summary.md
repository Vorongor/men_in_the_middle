# Результат ручного тестування весії Alpa.1.0

## Баги

**Критичні**

1. Міні-гра не запускається!
   Опис: З'являється червоний екран з надписом:

```
LateInitializationError: Field 'paddle' has not been initialized.
See also: https://docs/flutter.dev/testing/errors
```

Після чого гра не реагує, вийти допомагають тільки дебаг інструменти.

Log:

```
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 19 pixels on the right.

The relevant error-causing widget was:
  Row Row:file:///C:/Development/men_in_the_middle/lib/screens/attack_prep_screen.dart:335:14

To inspect this widget in Flutter DevTools, visit:
http://127.0.0.1:60801/cRgtLcp5jSY=/devtools//#/inspector?uri=http%3A%2F%2F127.0.0.1%3A60801%2FcRgtLcp5jSY%3D%2F&inspectorRef=inspector-0

The overflowing RenderFlex has an orientation of Axis.horizontal.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and
black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the
RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be
seen. If the content is legitimately bigger than the available space, consider clipping it with a
ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,
like a ListView.
The specific RenderFlex in question is: RenderFlex#4a325 relayoutBoundary=up5 OVERFLOWING:
  creator: Row ← Padding ← _PrepRow ← Column ← Padding ← Stack ← KeyedSubtree-[GlobalKey#52101] ←
    _BodyBuilder ← MediaQuery ← LayoutId-[<_ScaffoldSlot.body>] ← CustomMultiChildLayout ←
    _ActionsScope ← ⋯
  parentData: offset=Offset(0.0, 6.0) (can use size)
  constraints: BoxConstraints(0.0<=w<=232.0, 0.0<=h<=Infinity)
  size: Size(232.0, 19.0)
  direction: horizontal
  mainAxisAlignment: start
  mainAxisSize: max
  crossAxisAlignment: center
  textDirection: ltr
  verticalDirection: down
  spacing: 0.0
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════════════════════════

Another exception was thrown: A RenderFlex overflowed by 67 pixels on the right.
Another exception was thrown: A RenderFlex overflowed by 61 pixels on the right.
Another exception was thrown: A RenderFlex overflowed by 52 pixels on the right.
Another exception was thrown: LateInitializationError: Field 'paddle' has not been initialized.
Another exception was thrown: LateInitializationError: Field 'paddle' has not been initialized.
```

2. Гравець з 0 балансом без місій застрягає у мертвій точці - немає можливості ні просунутися (в борг), ні продати власні хард/софт елементи щоб поповнити баланс, Дошка оголошень не оновлюється з часом.

**Помірні**

3. Повідомлення перекривають активні кнопки, отрібно очікувати поки повідомлення зникнуть.

4. Покращення харду чи софту викидає на попередню сторінку.

5. Відсутня можливість перейти у налаштування з середини гри

**Незначні**

6. Немає опції видалити прочитані новини.

7. Під час підготовки атаки немає калькуляції твоєї сили атаки, потрібно додати наглядні показники.

8. Погано підібрана кольорова гама - дрібні шрифти губляться на екрані
