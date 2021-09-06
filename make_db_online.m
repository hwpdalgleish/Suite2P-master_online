drive = 'F';
user = 'Oliver';

i = 0;
db = [];
i = i+1;
db(i).mouse_name        = 'OG418';
db(i).date              = '20191006';
db(i).expts             = [1:3,6];
db(i).nchannels         = 1;
db(i).gchannel          = 1; 
db(i).nplanes           = 1;
db(i).planesToProcess   = db(i).nplanes;

ops0.RootStorage = [drive ':\Data\' user '\'];
% ops0.RootStorage = '/Users/henrydalgleish/Desktop/';