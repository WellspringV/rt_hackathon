import requests



def normalize_url(url):
    """
    Проверяет и нормализует URL 

    :param url: исходный URL
    :return: нормализованный URL
    """
    url = url.strip().replace('\n', '').replace('\r', '')

    if not url.startswith(('http://', 'https://')):
        url = 'http://' + url    
    return url


def check_keywords_on_website(url, keywords=['контакт-центр']):
    """
    Проверяет наличие ключевых слов на веб-сайте.
    
    Parameters:
    - keywords: Список ключевых слов для проверки.
    - url: URL веб-сайта для проверки.
    
    Returns:
    - True/False
    """
    try:
        headers = {
            "User-Agent": "Mozilla/5.0",
        }
        response = requests.get(url, headers=headers)
        if not (200 <= response.status_code <= 299):
            print(f"Ошибка при обращении к {url}: {response.status_code}")
            return False   
        
        html_content = response.text
        found_keywords = [keyword for keyword in keywords if keyword.lower() in html_content.lower()]
    except Exception as e:
        print(e)
        return False
    else:
        return bool(found_keywords)








if __name__ == "__main__":
    keywords = ['контакт-центр']
    with open('sites.txt') as f:
        urls = f.readlines()
    
    urls = [normalize_url(url) for url in urls]
    
    for url in urls:
        check_keywords_on_website(url)