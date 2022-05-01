from os import strerror
from subprocess import Popen
import requests
import time
import subprocess
import logging
import os
import signal
import json
import sys
from datetime import datetime

configFile = sys.argv[1] if len(sys.argv)==2 else "config.json"

try:
    with open(configFile) as json_data:
        config=json.load(json_data)
except:
    print("Missing config.json file. Make sure the configuration file is in the same folder")
    exit()

burpConfigs=config["burpConfigs"][0]
siteConfigs=config["sites"]

def set_logging():
    global rootLogger
    logFormatter = logging.Formatter("%(asctime)s [%(levelname)-5.5s]  %(message)s")
    rootLogger = logging.getLogger()
    NumericLevel = getattr(logging, burpConfigs["loglevel"].upper(), 10)
    rootLogger.setLevel(NumericLevel)

    fileHandler = logging.FileHandler("{0}/{1}.log".format(burpConfigs["logPath"], burpConfigs["logfileName"]))
    fileHandler.setFormatter(logFormatter)
    rootLogger.addHandler(fileHandler)

    consoleHandler = logging.StreamHandler()
    consoleHandler.setFormatter(logFormatter)
    rootLogger.addHandler(consoleHandler)

def execute_burp(site):
    cmd = burpConfigs["java"] + " --illegal-access=permit -jar -Xmx" + burpConfigs["memory"] + " -Djava.awt.headless=" \
        + str(burpConfigs["headless"]) + " " + burpConfigs["burpJar"] + " --project-file=" + site["project"] + " --unpause-spider-and-scanner --user-config-file=" + site["userburpfile"]
    try:
        rootLogger.debug("Executing Burp: " + str(cmd))
        p = Popen(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return p.pid
    except:
        rootLogger.error("Burp Suite failed to execute.")
        exit()

def check_burp(site):
    count = 0
    url = "http://127.0.0.1:1337/"+ site["apikey"] +"/v0.1/"
    time.sleep(10)
    while True:
        if count > burpConfigs["retry"]:
            rootLogger.error("Too many attempts to connect to Burp")
            exit()
        else:
            rootLogger.debug("Cheking API: " + str(url))
            init = requests.get(url)
            if init.status_code == 200:
                rootLogger.debug("API running, response code: " + str(init.status_code))
                # Let Brup time to load extensions
                time.sleep(30)
                break
            else:
                rootLogger.debug("Burp is not ready yet, response code: " + str(init.status_code))
                time.sleep(10)

def execute_scan(sites):
    data = '{"resource_pool":"Inter scan pool","scan_configurations":[{"config":"{\\"crawler\\":{\\"crawl_limits\\":{\\"maximum_crawl_time\\":150,\\"maximum_request_count\\":0,\\"maximum_unique_locations\\":1500},\\"crawl_optimization\\":{\\"breadth_first_until_depth\\":5,\\"consolidation_success_threshold\\":9,\\"crawl_strategy\\":\\"most complete\\",\\"crawl_strategy_customized\\":false,\\"discovered_destinations_group_size\\":20,\\"error_destination_multiplier\\":2,\\"form_destination_optimization_threshold\\":6,\\"form_submission_optimization_threshold\\":30,\\"idle_time_for_mutations\\":100,\\"link_fingerprinting_threshold\\":4,\\"logging_directory\\":\\"\\",\\"logging_enabled\\":false,\\"loopback_link_fingerprinting_threshold\\":4,\\"maximum_consolidation_items\\":15,\\"maximum_form_field_permutations\\":15,\\"maximum_form_permutations\\":50,\\"maximum_link_depth\\":5,\\"maximum_state_changing_sequences\\":40,\\"maximum_state_changing_sequences_length\\":5,\\"maximum_state_changing_sequences_per_destination\\":7,\\"maximum_unmatched_anchor_tolerance\\":0,\\"maximum_unmatched_form_tolerance\\":0,\\"maximum_unmatched_frame_tolerance\\":0,\\"maximum_unmatched_iframe_tolerance\\":0,\\"maximum_unmatched_image_area_tolerance\\":0,\\"maximum_unmatched_redirect_tolerance\\":0,\\"recent_destinations_buffer_size\\":12,\\"total_unmatched_feature_tolerance\\":0,\\"trimmed_consolidation_items\\":7},\\"customization\\":{\\"allow_out_of_scope_resources\\":true,\\"browser_based_navigation_mode\\":\\"only_if_hardware_supports\\",\\"customize_user_agent\\":false,\\"maximum_items_from_sitemap\\":1000,\\"maximum_speculative_links\\":1000,\\"parse_api_definitions\\":true,\\"request_robots_txt\\":true,\\"request_sitemap\\":true,\\"request_speculative\\":true,\\"submit_forms\\":true,\\"timeout_for_in_progress_resource_requests\\":10,\\"use_headed_browser_for_crawl\\":false,\\"user_agent\\":\\"\\"},\\"error_handling\\":{\\"number_of_follow_up_passes\\":1,\\"pause_task_requests_timed_out_count\\":0,\\"pause_task_requests_timed_out_percentage\\":0},\\"login_functions\\":{\\"attempt_to_self_register_a_user\\":true,\\"trigger_login_failures\\":true}}}","type":"CustomConfiguration"},{"config":"{\\"scanner\\":{\\"audit_optimization\\":{\\"consolidate_passive_issues\\":true,\\"follow_redirections\\":true,\\"maintain_session\\":true,\\"scan_accuracy\\":\\"normal\\",\\"scan_speed\\":\\"thorough\\",\\"skip_ineffective_checks\\":true},\\"error_handling\\":{\\"consecutive_audit_check_failures_to_skip_insertion_point\\":5,\\"consecutive_insertion_point_failures_to_fail_audit_item\\":5,\\"number_of_follow_up_passes\\":1,\\"pause_task_failed_audit_item_count\\":0,\\"pause_task_failed_audit_item_percentage\\":0},\\"frequently_occurring_insertion_points\\":{\\"quick_scan_body_params\\":true,\\"quick_scan_cookies\\":true,\\"quick_scan_entire_body\\":true,\\"quick_scan_http_headers\\":true,\\"quick_scan_param_name\\":true,\\"quick_scan_url_params\\":true,\\"quick_scan_url_path_filename\\":true,\\"quick_scan_url_path_folders\\":true},\\"ignored_insertion_points\\":{\\"skip_all_tests_for_parameters\\":[{\\"enabled\\":true,\\"expression\\":\\"version\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"xml_attribute\\"},{\\"enabled\\":true,\\"expression\\":\\"encoding\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"xml_attribute\\"},{\\"enabled\\":true,\\"expression\\":\\"standalone\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"xml_attribute\\"},{\\"enabled\\":true,\\"expression\\":\\"xmlns.*\\",\\"item\\":\\"name\\",\\"match_type\\":\\"matches_regex\\",\\"parameter\\":\\"xml_attribute\\"},{\\"enabled\\":true,\\"expression\\":\\"xml:lang\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"xml_attribute\\"},{\\"enabled\\":true,\\"expression\\":\\"lang\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"xml_attribute\\"}],\\"skip_server_side_injection_for_parameters\\":[{\\"enabled\\":true,\\"expression\\":\\"aspsessionid.*\\",\\"item\\":\\"name\\",\\"match_type\\":\\"matches_regex\\",\\"parameter\\":\\"cookie\\"},{\\"enabled\\":true,\\"expression\\":\\"asp.net_sessionid\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"cookie\\"},{\\"enabled\\":true,\\"expression\\":\\"__eventtarget\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"body_parameter\\"},{\\"enabled\\":true,\\"expression\\":\\"__eventargument\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"body_parameter\\"},{\\"enabled\\":true,\\"expression\\":\\"__viewstate\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"body_parameter\\"},{\\"enabled\\":true,\\"expression\\":\\"__eventvalidation\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"body_parameter\\"},{\\"enabled\\":true,\\"expression\\":\\"jsessionid\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"any_parameter\\"},{\\"enabled\\":true,\\"expression\\":\\"cfid\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"cookie\\"},{\\"enabled\\":true,\\"expression\\":\\"cftoken\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"cookie\\"},{\\"enabled\\":true,\\"expression\\":\\"PHPSESSID\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"cookie\\"},{\\"enabled\\":true,\\"expression\\":\\"session_id\\",\\"item\\":\\"name\\",\\"match_type\\":\\"is\\",\\"parameter\\":\\"cookie\\"}]},\\"insertion_point_types\\":{\\"insert_body_params\\":true,\\"insert_cookies\\":true,\\"insert_entire_body\\":true,\\"insert_http_headers\\":true,\\"insert_param_name\\":true,\\"insert_url_params\\":true,\\"insert_url_path_filename\\":true,\\"insert_url_path_folders\\":true},\\"issues_reported\\":{\\"scan_type_intrusive_active\\":true,\\"scan_type_javascript_analysis\\":true,\\"scan_type_light_active\\":true,\\"scan_type_medium_active\\":true,\\"scan_type_passive\\":true,\\"select_individual_issues\\":false,\\"selected_issues\\":[],\\"store_issues_within_queue_items\\":false},\\"javascript_analysis\\":{\\"fetch_out_of_scope_resources\\":true,\\"max_dynamic_time_per_item\\":30,\\"max_static_time_per_item\\":30,\\"request_missing_dependencies\\":true,\\"use_dynamic_analysis\\":true,\\"use_static_analysis\\":true},\\"misc_insertion_point_options\\":{\\"max_insertion_points_per_base_request\\":30,\\"use_nested_insertion_points\\":true},\\"modifying_parameter_locations\\":{\\"body_to_cookie\\":false,\\"body_to_url\\":false,\\"cookie_to_body\\":false,\\"cookie_to_url\\":false,\\"url_to_body\\":false,\\"url_to_cookie\\":false}}}","type":"CustomConfiguration"}],"urls":['
    
    count = 0
    for site in sites:
        if count == 1: 
            data = data + ','
        count = 1
        data = data + '"' + site["scanURL"] + '"'
        
    data = data + ']}'
    url="http://127.0.0.1:1337/" + site["apikey"] + "/v0.1/scan"
    rootLogger.info("Starting scan: ")
    scan = requests.post(url, data=data)
    rootLogger.debug("Task ID: " + scan.headers["Location"])
    while True:
        url="http://127.0.0.1:1337/" + site["apikey"] + "/v0.1/scan/" + scan.headers["Location"]
        scanresults = requests.get(url)
        data = scanresults.json()
        rootLogger.info("Current status: " + data["scan_status"])
        if data["scan_status"] == "failed":
            rootLogger.error("Scan failed")
            kill_burp()
            exit()
        elif data["scan_status"] == "succeeded":
            rootLogger.info("Scan competed")
            return data
        else:
            rootLogger.debug("Waiting 5 min before cheking the status again")
            time.sleep(300)

def kill_burp(child_pid):
    rootLogger.info("Killing Burp.")
    try:
            os.kill(child_pid, signal.SIGTERM)
            rootLogger.debug("Burp killed")
    except:
            rootLogger.error("Failed to stop Burp")

def get_data(data):
    for issue in data["issue_events"]:
        rootLogger.info("Vulnerability - Name: " + issue["issue"]["name"] + " Path: " + issue["issue"]["path"] + " Severity: " + issue["issue"]["severity"])
    file = "BurpScan-" + datetime.now().strftime("%Y_%m_%d-%I_%M_%S_%p") + ".txt"
    file = burpConfigs["ScanOutput"] + file
    rootLogger.info("Writing full results to: "+ file)
    with open(file, "w") as f:
        f.write(str(data["issue_events"]))

def main():
    set_logging()
    # Execute BurpSuite Pro
    child_pid = execute_burp(config["sites"][0])
    # Check if API burp is up
    check_burp(config["sites"][0])
    # Execute Scan
    data = execute_scan(config["sites"])
    # Get Vulnerability data
    get_data(data)
    # Stop Burp
    rootLogger.info("Scan finished, killing Burp.")
    kill_burp(child_pid)

if __name__ == '__main__':
    main() 
