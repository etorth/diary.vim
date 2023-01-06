Keep diary on github, by default this plugin creates following private repo:
```url
https://github.com/<your-github-login>/diary.git
```

Usage:
- This plugin requires ```python3``` and package ```PyGithub```:
```shell
pip3 install PyGithub
```

- Create a minimal config file ```$HOME/.diary.json``` or ```C:\Users\<user-id>\.diary.json```:

```json
{
    "github-token": "<your-github-token>"
}
```

- This plugin adds two most-commonly-used commands:
```vim
:DiaryNew       " create a new unnamed tab and pull in any existing diary content
:DiarySubmit    " submit current content
```

Note:
- Try ```:help PyGithubDiary``` for more features.
- Don't forget to adjust access permission of your ```.diary.json``` file for security.
- Sample diaries generated by ```:DiaryViewHtml```:

  <img src="https://github.com/etorth/PyGithubDiary/raw/main/screenshot.png"/>
