#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <regex>
#include <filesystem> // Include the filesystem header

namespace fs = std::filesystem; // Use the filesystem namespace



void check_runtime(const std::string& runtime, const std::string& jobid, const std::string& attempt, std::ofstream& output_file) {
    int hh, mm, ss;
    sscanf(runtime.c_str(), "%d:%d:%d", &hh, &mm, &ss);
    int total_seconds = hh * 3600 + mm * 60 + ss;
    if (total_seconds < 30) {
        output_file << "Failed: JobId=" << jobid << " RunTime=" << runtime << " Attempt=" << attempt << "\n";
    } else {
        output_file << "Succeeded: JobId=" << jobid << " RunTime=" << runtime << " Attempt=" << attempt << "\n";
    }
}

int main() {
    const std::string directory = "./output/";
    const std::string output_file_path = "./results.txt";
    std::regex attempt_regex(R"(DM\+Baryons_2023\.08\.15:(\d+))"); // Define attempt_regex

    std::ofstream output_file(output_file_path);
    if (!output_file.is_open()) {
        std::cerr << "Failed to open output file.\n";
        return 1;
    }

    for (const auto& entry : fs::directory_iterator(directory)) {
        std::string filename = entry.path().filename().string();
        std::smatch attempt_match;
        if (std::regex_search(filename, attempt_match, attempt_regex) && attempt_match.size() > 1) {
            std::string attempt = attempt_match.str(1);

            std::ifstream file(entry.path(), std::ios::in | std::ios::binary | std::ios::ate);
            if (!file.is_open()) {
                std::cerr << "Failed to open file: " << entry.path() << "\n";
                continue;
            }

            std::string content;
            std::streampos pos = file.tellg();
            int newline_count = 0;
            while (pos > static_cast<std::streamoff>(0) && newline_count < 100) { // Change here
                pos = pos - static_cast<std::streamoff>(1); // Change here
                file.seekg(pos);
                if (file.get() == '\n') {
                    newline_count++;
                }
            }

            std::getline(file, content, '\0');
            file.close();

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
                check_runtime(runtime, jobid, attempt, output_file);
            } else {
                output_file << "Could not extract information from file: " << entry.path() << "\n";
            }
        }
    }

    output_file.close();
    std::cout << "Results saved to " << output_file_path << "\n";
    return 0;
}

