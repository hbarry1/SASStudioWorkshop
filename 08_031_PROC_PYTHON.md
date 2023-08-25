![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# PROC PYTHON

- [Log on to SAS Studio](#log-on-to-sas-studio)
- [Experiment Callback Methods](#experiment-callback-methods)
- [Import a Specific File Format in SAS](#import-a-specific-file-format-in-sas)
  - [Option 1: Import an Avro file in SAS](#option-1-import-an-avro-file-in-sas)
  - [Option 2: Import a JSON file in SAS](#option-2-import-a-json-file-in-sas)

## Log on to SAS Studio

In your Google Chrome browser, open **SAS Studio** (**SAS Viya** bookmark, **sasadm/lnxsas**, **Develop Code and Flows** in the **ANALYTICS LIFE CYCLE** Applications menu).

## Experiment Callback Methods

PROC PYTHON callback methods are documented [here](https://go.documentation.sas.com/doc/en/pgmsascdc/v_024/proc/n1x71i41z1ewqsn19j6k9jxoi5fa.htm).

The code skeleton for running Python code from a SAS Compute Server is as follows:

```sas
proc python ;
    submit ;

# Insert your Python code here
# Start at beginning of line

    endsubmit ;
run ;
```

>*NB: you can also directly write Python code in a new "Python Program" in SAS Studio.*

Perform the following (accumulate your Python code between the ```submit``` and ```endsubmit``` and run your PROC PYTHON entirely each time):

1. Use a PROC PYTHON callback method to run the following SAS code from Python:

```sas
data prdsale ; set sashelp.prdsale ; run ;
```

<details>

<summary>Solution</summary>

>```python
>SAS.submit("data prdsale ; set sashelp.prdsale ; run ;")
>```

</details>

2. Use a PROC PYTHON callback method to get the contents of the SYSLAST macro-variable and print it in Python output.

<details>

<summary>Solution</summary>

>```python
>mytable=SAS.symget("SYSLAST")
>print("The last table I created is",mytable)
>```

</details>

3. Use a PROC PYTHON callback method to get the path of the WORK library (*PATHNAME* SAS function) and print it in Python output.

<details>

<summary>Solution</summary>

>```python
>workpath=SAS.sasfnc("pathname", "work")
>print("The SASWORK library points to", workpath)
>```

</details>

4. Use a PROC PYTHON callback method to bring the SAS table created earlier in Python as a Pandas DataFrame and print some metadata information from the DataFrame using the *info()* method.

<details>

<summary>Solution</summary>

>```python
>df = SAS.sd2df(mytable)
>df.info()
>```

</details>

5. Print a cross-tabulation table built on the DataFrame using the *pandas.crosstab* function.

<details>

<summary>Solution</summary>

>```python
>import pandas as pd
>import numpy as np
>pd.crosstab(df.COUNTRY, df.YEAR, values=df.ACTUAL, aggfunc=np.sum)
>```

</details>

6. Call the following REST API (http://api.open-notify.org/astros.json) to get the list of people currently in Space at this moment and print the resulting dictionary.

<details>

<summary>Solution</summary>

>```python
>import requests
>json_response = requests.get("http://api.open-notify.org/astros.json").json()
>print("Response from the HTTP request:",json_response)
>```

</details>

7. Use a PROC PYTHON callback method to assign a SAS macro-variable with the number of people currently in Space. The function to parse the dictionary and get the number of people is ```json_response["number"]```.

<details>

<summary>Solution</summary>

>```python
>SAS.symput("nb_people_in_Space", json_response["number"])
>```

</details>

8. Finally print the SAS macro-variable in the SAS log, after the PROC PYTHON step, to check if the macro-variable has been successfully created.

<details>

<summary>Solution</summary>

>```sas
>%put "Right now, there are &nb_people_in_Space people in Space." ;
>```

</details>

<details>

<summary><b>Complete Solution</b></summary>

>```sas
>proc python ;
>    submit ;
>
>SAS.submit("data prdsale ; set sashelp.prdsale ; run ;")
>
>mytable=SAS.symget("SYSLAST")
>print("The last table I created is",mytable)
>
>workpath=SAS.sasfnc("pathname", "work")
>print("The SASWORK library points to", workpath)
>
>df = SAS.sd2df(mytable)
>df.info()
>
>import pandas as pd
>import numpy as np
>pd.crosstab(df.COUNTRY, df.YEAR, values=df.ACTUAL, aggfunc=np.sum)
>
>import requests
>json_response = requests.get("http://api.open-notify.org/astros.json").json()
>print("Response from the HTTP request:",json_response)
>
>SAS.symput("nb_people_in_Space", json_response["number"])
>
>    endsubmit ;
>run ;
>
>%put "Right now, there are &nb_people_in_Space people in Space." ;
>```

</details>

## Import a Specific File Format in SAS

Do one of the two following options.

### Option 1: Import an Avro file in SAS

SAS does not support directly the Avro file format. Some Python packages allow to read Avro files easily.

The code to import an Avro file in a Pandas DataFrame is as follows:

```python
import pandas
from fastavro import reader

fo = open('/gelcontent/data/BIG_DATA_FORMATS/avro/userdata_avro/userdata2.avro', 'rb')
records = [record for record in reader(fo)]
df = pandas.DataFrame.from_records(records)
df['registration_dttm'] = pandas.to_datetime(df['registration_dttm'])
```

Embed this Python code in a SAS PROC PYTHON step and adapt it to actually import the Avro file in the WORK.USERDATA SAS data set.

Then check if the table has been successfully created in SAS.

>*Tip: use a [PROC PYTHON callback method](https://go.documentation.sas.com/doc/en/pgmsascdc/v_024/proc/n1x71i41z1ewqsn19j6k9jxoi5fa.htm).*

<details>

<summary>Solution</summary>

>```sas
>proc python ;
>    submit ;
>
>import pandas
>from fastavro import reader
>
>fo = open('/gelcontent/data/BIG_DATA_FORMATS/avro/userdata_avro/userdata2.avro', 'rb')
>records = [record for record in reader(fo)]
>df = pandas.DataFrame.from_records(records)
>df['registration_dttm'] = pandas.to_datetime(df['registration_dttm'])
>ds = SAS.df2sd(df,"userdata")
>
>    endsubmit ;
>run ;
>```

</details>

### Option 2: Import a JSON file in SAS

The JSON file we want to import looks like this:

![](img/franir_2022-04-29-15-25-15.png)

We want to generate 1 record per measure ("Text") and retain information from the parent objects, so 5 output records per JSON input record, 25 records in total (there are 5 JSON records).

>*NB: it is possible to read this JSON file with SAS and the JSON library engine. This involves multiple steps including the creation of a JSON MAP. Python offers a smart way to parse it once.*

The code to import this JSON file in a Pandas DataFrame is as follows:

```python
import pandas as pd
import json
f = open("/gelcontent/data/BIG_DATA_FORMATS/json/smartFridges_brackets.json")
data = json.load(f)
df = pd.json_normalize(data, record_path=['Objects', 'Object', 'InfoItem', 'value'],
    meta=[['Objects', 'Object', 'id'],
        ['Objects', 'Object', 'type'],
        ['Objects', 'Object', 'InfoItem', 'name'],
        ['Objects', 'Object', 'InfoItem', 'description']])
df['dateTime'] = pd.to_datetime(df['dateTime'])
df.head()
df.info()
df.rename(columns = {
    'Text':'measure',
    'Objects.Object.id':'deviceId',
    'Objects.Object.type':'deviceType',
    'Objects.Object.InfoItem.name':'measureName',
    'Objects.Object.InfoItem.description':'measureDescription',
    'Objects.Object.InfoItem.name':'measureName'
    }, inplace = True)
df.info()
```

Embed this Python code in a SAS PROC PYTHON step and adapt it to actually import the JSON file in the WORK.SMARTFRIDGES SAS data set.

Then check if the table has been successfully created in SAS.

>*Tip: use a [PROC PYTHON callback method](https://go.documentation.sas.com/doc/en/pgmsascdc/v_024/proc/n1x71i41z1ewqsn19j6k9jxoi5fa.htm).*

<details>

<summary>Solution</summary>

>```sas
>proc python ;
>    submit ;
>
>import pandas as pd
>import json
>f = open("/gelcontent/data/BIG_DATA_FORMATS/json/smartFridges_brackets.json")
>data = json.load(f)
>df = pd.json_normalize(data, record_path=['Objects', 'Object', 'InfoItem', 'value'],
>    meta=[['Objects', 'Object', 'id'],
>        ['Objects', 'Object', 'type'],
>        ['Objects', 'Object', 'InfoItem', 'name'],
>        ['Objects', 'Object', 'InfoItem', 'description']])
>df['dateTime'] = pd.to_datetime(df['dateTime'])
>df.head()
>df.info()
>df.rename(columns = {
>    'Text':'measure',
>    'Objects.Object.id':'deviceId',
>    'Objects.Object.type':'deviceType',
>    'Objects.Object.InfoItem.name':'measureName',
>    'Objects.Object.InfoItem.description':'measureDescription',
>    'Objects.Object.InfoItem.name':'measureName'
>    }, inplace = True)
>df.info()
>ds = SAS.df2sd(df,"smartFridges")
>
>    endsubmit ;
>run ;
>```

</details>
