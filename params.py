# Redefining the function to calculate and write permutations to CSV after reset

# Define the file path for the new CSV file
results_file_path = 'F:\Python projects\MATwister/permutations_calculated.csv'

# Function to calculate and write permutations to CSV
def calculate_and_write_permutations(file_path):
    list1 = list(range(10, 16))  # 10 to 15 inclusive
    list2 = list(range(19, 31))  # 19 to 30 inclusive
    list3 = list(range(40, 61))  # 40 to 60 inclusive
    
    # Generate all possible combinations
    correct_perms = [(x, y, z) for x in list1 for y in list2 for z in list3]
    
    # Open a new file and write the header and the permutations
    with open(file_path, 'w') as file:
        # Write the header
        file.write('First Number,Second Number,Third Number\n')
        
        # Write each permutation
        for perm in correct_perms:
            line = '{},{},{}\n'.format(perm[0], perm[1], perm[2])
            file.write(line)

# Call the function to calculate and write the permutations
calculate_and_write_permutations(results_file_path)

results_file_path
