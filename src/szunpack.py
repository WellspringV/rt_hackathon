import os
from py7zr import SevenZipFile




class SZUnpack:
    def __init__(self, archive):
        self.archive = archive

    def unpack_archive(self,  path=None, extra=None):
        with SevenZipFile(self.archive) as arc:
            arc.extractall(path)

    @property
    def is_unpacked(self, path='data', file_count=3):
        if not os.path.exists(path):
            return False
        if not len(os.listdir(path)) == file_count:
            return False  
        return True

    def remove_archive(self):
        if self.is_unpacked:
            os.remove(self.archive)



        


    




if __name__ == "__main__":
    unpack = SZUnpack('data.7z')


