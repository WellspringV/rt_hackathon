import os
import logging
import urllib
from urllib.parse import urlparse
from pathlib import Path

import requests




logger = logging.getLogger(__name__)

class DownloadException(Exception):    pass


class DownloadManager:
    def __init__(self, url: str) -> None:
        self.url = url
        self.filename = ""
        self.response_headers = {}
        self.origin_file_size = 0  
        self.session = None    
        self.ready_to_dowload = False 
        self._prepare_session()
                 
    def _get_response_headers(self) -> dict:      
        request = urllib.request.Request(self.url, method="HEAD")
        response = urllib.request.urlopen(request)
        self.response_headers = response.headers
        
    def _get_origin_size(self) -> int:
        size = int(self.response_headers.get('Content-Length', 0))
        return size
    
    def _prepare_session(self) -> None:
        self.session = requests.Session()
        try:
            self._get_response_headers()
        except Exception as e:
            logger.info(f'Prepare session failed with error {e}')
        else:
            self.origin_file_size = self._get_origin_size()
            self.ready_to_dowload = True    
    
    @property
    def local_file_exists(self) -> bool:
        if os.path.exists(self.filename):
            return True    

    def download(self):

        if not self.ready_to_dowload:
            raise DownloadException('Not ready for download')
        
        headers = {
            "user-agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 "
            "YaBrowser/22.11.3.838 Yowser/2.5 Safari/537.36", 
        }

        try:
            rs = self.session.get(url=self.url, headers=headers, stream=True, timeout=15)
            if 200 <= rs.status_code <= 299:
                name = rs.headers.get('filename')
                if not name:
                    name = Path(urlparse(rs.url).path).name
                with open(name, 'wb') as file:
                    for part in rs.iter_content(1024 * 1024):
                        file.write(part)
            else:
                return
        except Exception as ex:
            logger.info(ex)
            return




def main():
    url = 'https://contestfiles.storage.yandexcloud.net/companies/76b19c3f3c417fc4f9623ba4d00cbde8/data.7z?roistat_visit=1390266'    
    Downloader = DownloadManager(url)
    Downloader.download()
    


if __name__ == "__main__":
    main()