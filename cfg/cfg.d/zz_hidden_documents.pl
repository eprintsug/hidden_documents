use EPrints::DataObj::Document::HiddenDocument;

$c->{plugins}->{"InputForm::Component::HiddenUpload"}->{params}->{disable} = 0;
$c->{plugins}->{"InputForm::Component::HiddenDocuments"}->{params}->{disable} = 0;

$c->{plugins}->{"Screen::EPrint::UploadMethod::HiddenFile"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::EPrint::HiddenDocument::Remove"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::EPrint::HiddenDocument::Files"}->{params}->{disable} = 0;

# unlikley we would want to upload secret files via a URL so disabled by default
$c->{plugins}->{"Screen::EPrint::UploadMethod::HiddenURL"}->{params}->{disable} = 1;

$c->{datasets}->{hidden_document} = {
    class => "EPrints::DataObj::Document::HiddenDocument",
    sqlname => "hidden_document",
    name => "hidden_document",
    index => 0,
    import => 0,
};


push @{ $c->{fields}->{eprint} },
    { name=>"hidden_documents", type=>"subobject", datasetid=>'hidden_document',
        multiple=>1, text_index=>0, dataset_fieldname=>'', dataobj_fieldname=>'eprintid' };
