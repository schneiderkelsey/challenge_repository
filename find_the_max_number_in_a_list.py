def find_max_with_loop(numbers):
    if not numbers:
        return None  # Handle empty list case
    max_value = numbers[0]
    for num in numbers:
        if num > max_value:
            max_value = num
    return max_value