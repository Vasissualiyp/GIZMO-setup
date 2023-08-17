#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <regex>
#include <filesystem>
#include <map>

// Function to read the last 100 lines of a file
std::string read_last_lines(const std::filesystem::path& path) {
    std::ifstream file(path, std::ios::in | std::ios::binary | std::ios::ate);
    std::string content;
    std::streampos pos = file.tellg();
    int newline_count = 0;
    while (pos > static_cast<std::streamoff>(0) && newline_count < 100) {
        pos = pos - static_cast<std::streamoff>(1);
        file.seekg(pos);
        if (file.get() == '\n') {
            newline_count++;
        }
    }
    std::getline(file, content, '\0');
    file.close();
    return content;
}

// Function to process a single file
void process_file(const std::filesystem::path& path, std::map<int, std::string>& results) {
    std::string filename = path.filename().string();
    std::regex attempt_regex(R"(DM\+Baryons_2023\.08\.15:(\d+))");
    std::smatch attempt_match;
    if (std::regex_search(filename, attempt_match, attempt_regex) && attempt_match.size() > 1) {
        int attempt = std::stoi(attempt_match.str(1));
        std::string content = read_last_lines(path);

        // Extract runtime and jobid
        std::regex runtime_regex("RunTime=(\\d\\d:\\d\\d:\\d\\d)");
        std::regex jobid_regex("JobId=(\\d+)");
        std::smatch match;
        std::string runtime, jobid;

        if (std::regex_search(content, match, runtime_regex) && match.size() > 1) {
            runtime = match.str(1);
        }

        if (std::regex_search(content, match, jobid_regex) && match.size() > 1) {
            jobid = match.str(1);
        }

        if (!runtime.empty() && !jobid.empty()) {
            int hh, mm, ss;
            sscanf(runtime.c_str(), "%d:%d:%d", &hh, &mm, &ss);
            int total_seconds = hh * 3600 + mm * 60 + ss;
            std::string status = (total_seconds < 30) ? "Failed" : "Succeeded";
            results[attempt] = status + ": JobId=" + jobid + " RunTime=" + runtime + " Attempt=" + std::to_string(attempt);
        }
    }
}

int main() {
    const std::string directory = "./output/";
    const std::string output_file_path = "./results.txt";
    std::map<int, std::string> results; // Store results in a map to sort by attempt number

    for (const auto& entry : std::filesystem::directory_iterator(directory)) {
        process_file(entry.path(), results);
    }

    // Write results to the output file
    std::ofstream output_file(output_file_path);
    if (!output_file.is_open()) {
        std::cerr << "Failed to open output file.\n";
        return 1;
    }
    for (const auto& result : results) {
        output_file << result.second << "\n";
    }
    output_file.close();

    std::cout << "Results saved to " << output_file_path << "\n";
    return 0;
}

