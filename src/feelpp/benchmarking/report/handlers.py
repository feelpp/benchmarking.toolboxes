import os, json
import girder_client

class DownloadHandler:
    def __init__(self,download_base_dir):
        self.download_base_dir = download_base_dir

    def downloadFolder(self, folder_id, output_dir):
        pass

class GirderHandler(DownloadHandler):
    def __init__(self, download_base_dir):
        """ Initialize the Girder handler """
        super().__init__(download_base_dir = download_base_dir)
        self.base_url = "https://girder.math.unistra.fr/api/v1"
        self.initClient()

    def initClient(self):
        """ Initialize the Girder client """
        self.client = girder_client.GirderClient(apiUrl=self.base_url)
        self.client.authenticate(apiKey=os.environ["GIRDER_API_KEY"])

    def downloadFolder(self, folder_id, output_dir):
        """ Download a folder from Girder recursively
        Args:
            folder_id (str): The ID of the folder to download
            output_path (str): The path to the output directory
        Returns:
            list: The list of downloaded files inside the output directory
        """
        self.client.downloadFolderRecursive(folder_id, f"{self.download_base_dir}/{output_dir}")

        return os.listdir(f"{self.download_base_dir}/{output_dir}")



class ConfigHandler:
    def __init__(self, config_filepath):
        """ Initialize the configuration handler
        Args:
            config_filepath (str): The path to the configuration file
        """

        #Checks
        self.checkFileExists(filepath=config_filepath)
        self.checkFileExtension(filepath=config_filepath, extension="json")

        with open(config_filepath, 'r') as file:
            config = json.load(file)

        self.machines = config["machines"]
        self.applications = config["applications"]
        self.execution_mapping = config["execution_mapping"]

    def checkFileExists(self, filepath):
        """ Check if a file exists
        Args:
            filepath (str): The path to the file
        Raises:
            FileNotFoundError: If the file does not exist
        """
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"File {filepath} not found")

    def checkFileExtension(self, filepath, extension):
        """ Check if the file has a given extension file
        Args:
            filepath (str): The path to the file
            extension (str): The extension to check (without the dot)
        Raises:
            ValueError: If the file does not have the given extension
        """
        if not filepath.split(".")[-1] == extension:
            raise ValueError("The config file must be a JSON file")

    def getMergedMachineInfo(self, machine_id):
        """inner merge of 'benchmarks' and respective applications contained inside
        Args:
            machine_id (str): The id of the machine
        Returns:
            dict: The merged info
        """
        benchmark_info = {}
        for app_id, app_info in self.execution_mapping.get(machine_id,{}).items():
            benchmark_info[app_id] = {k:v for k,v in app_info.items() if k != "test_cases"}
            benchmark_info[app_id].update({k:v for k,v in self.applications[app_id].items() if k != "test_cases"})
            benchmark_info[app_id]["test_cases"] = {}
            for test_case in app_info["test_cases"]:
                benchmark_info[app_id]["test_cases"][test_case] = self.applications[app_id]["test_cases"][test_case]

        return benchmark_info

