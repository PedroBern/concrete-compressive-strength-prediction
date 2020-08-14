from shutil import copyfile
import re

copyfile('references.bib', 'generated/references.bib')

filenames = [
	'Abstract_&_Setup.Rmd',
	'Introduction.Rmd',
 'Materials_and_methods__Materials.Rmd',
 'Materials_and_methods__Replicability.Rmd',
 'Materials_and_methods__Obtaining_the_data.Rmd',
 'Materials_and_methods__Data_preparation.Rmd',
 'Materials_and_methods__Data_visualization.Rmd',
	'Materials_and_methods__Machine_learning_models.Rmd',
	'Results.Rmd',
	'Discussion.Rmd',
	'Literature_cited.Rmd',
	'Appendix_1__Virtual_environment.Rmd',
	'Appendix_2__Online_repository.Rmd',
	'Appendix_3__Codes.Rmd'
	]


def generate_appendix_code_chunk(title, chunk_name):
    s = "##" + title + "\n\n"
    s += "```{r show-"
    s += chunk_name
    s +=  ", ref.label='"
    s += chunk_name
    s +=  "', ref='show-"
    s += chunk_name
    s +=  "', eval=FALSE}\n```\n\n"
    return(s)

def generate_appendix_3_subsection(file, L="EN", hastags=2):
    with open("templates/" + file) as infile:
        f = infile.read()
        file_title = re.findall("<"+L+">\s*(#{"+str(hastags)+"}.*)\s", f)[0]
        titles = re.findall("^#<"+L+".*?>(#.+?)</"+L+">", f, flags=re.MULTILINE)
        chunk_names = re.findall("```{r\s([\w|-]*),", f, flags=re.DOTALL)
        s = ""
        if hastags == 1:
            s = "#"	
        s += file_title + "\n"
        for i in range(len(titles)):
            s += generate_appendix_code_chunk(titles[i], chunk_names[i])
        return(s)

with open('generated/paper_EN.Rmd', 'w') as outfile:
    for fname in filenames:
        with open("templates/" + fname) as infile:
            f = infile.read()
            f = re.sub("#?<PT.*?>.+?#?</PT>", '', f, flags=re.DOTALL)
            f = re.sub("#?<EN>|#?</EN>", '', f, flags=re.DOTALL)
            f = re.sub(r'\n+', '\n', f, flags=re.DOTALL)
            f = re.sub(r'(#{2,})', '\n\g<1>', f, flags=re.DOTALL)
            f = re.sub(r'\&nbsp;', '\n&nbsp;\n', f, flags=re.DOTALL)
            outfile.write(f + "\n\n")
    outfile.write(generate_appendix_3_subsection(
    	"Materials_and_methods__Obtaining_the_data.Rmd", L="EN"
    	))
    outfile.write(generate_appendix_3_subsection(
    	"Materials_and_methods__Data_preparation.Rmd", L="EN"
    	))
    outfile.write(generate_appendix_3_subsection(
    	"Materials_and_methods__Data_visualization.Rmd", L="EN"
    	))
    outfile.write(generate_appendix_3_subsection(
    	"Materials_and_methods__Machine_learning_models.Rmd", L="EN"
    ))
    outfile.write(generate_appendix_3_subsection(
    	"Results.Rmd", L="EN", hastags=1
    ))
    outfile.write(generate_appendix_3_subsection(
    	"Discussion.Rmd", L="EN", hastags=1
    ))
            
with open('generated/paper_PT.Rmd', 'w') as outfile:
    for fname in filenames:
        with open("templates/" + fname) as infile:
            f = infile.read()
            f = re.sub("#?<EN.*?>.+?#?</EN>", '', f, flags=re.DOTALL)
            f = re.sub("#?<PT>|#?</PT>", '', f, flags=re.DOTALL)
            f = re.sub(r'\n+', '\n', f, flags=re.DOTALL)
            f = re.sub(r'(#{2,})', '\n\g<1>', f, flags=re.DOTALL)
            f = re.sub(r'\&nbsp;', '\n&nbsp;\n', f, flags=re.DOTALL)
            outfile.write(f + "\n\n")
    outfile.write(generate_appendix_3_subsection(
    	"Materials_and_methods__Obtaining_the_data.Rmd", L="PT"
    	))
    outfile.write(generate_appendix_3_subsection(
    	"Materials_and_methods__Data_preparation.Rmd", L="PT"
    	))
    outfile.write(generate_appendix_3_subsection(
    	"Materials_and_methods__Data_visualization.Rmd", L="PT"
    	))
    outfile.write(generate_appendix_3_subsection(
    	"Materials_and_methods__Machine_learning_models.Rmd", L="PT"
    ))
    outfile.write(generate_appendix_3_subsection(
    	"Results.Rmd", L="PT", hastags=1
    ))
    outfile.write(generate_appendix_3_subsection(
    	"Discussion.Rmd", L="PT", hastags=1
    ))

