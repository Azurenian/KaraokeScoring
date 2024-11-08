function simpleGui
    % Create a simple GUI with a button to add two numbers
    f = figure('Position', [200, 200, 400, 200]);

    % Input fields for two numbers
    uicontrol('Style', 'text', 'Position', [50, 120, 100, 30], 'String', 'Number 1:');
    num1 = uicontrol('Style', 'edit', 'Position', [150, 125, 100, 30]);

    uicontrol('Style', 'text', 'Position', [50, 80, 100, 30], 'String', 'Number 2:');
    num2 = uicontrol('Style', 'edit', 'Position', [150, 85, 100, 30]);

    % Button to calculate sum
    uicontrol('Style', 'pushbutton', 'Position', [150, 30, 100, 40], 'String', 'Add', ...
              'Callback', @addCallback);

    % Output field for the result
    resultText = uicontrol('Style', 'text', 'Position', [270, 85, 100, 30], 'String', '');

    % Callback function for button press
    function addCallback(~, ~)
        a = str2double(num1.String);
        b = str2double(num2.String);
        result = a + b;
        resultText.String = num2str(result);
    end
end
